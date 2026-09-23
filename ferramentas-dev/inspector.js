(function(){
  'use strict';
  if(window.__fdiInspectorLoaded) return;
  window.__fdiInspectorLoaded = true;

  var CELL = 40;
  var TIPOS = {
    botao:'Botão: aciona uma ação quando clicado.',
    aba:'Aba: alterna entre conteúdos relacionados na mesma área da tela.',
    card:'Card: bloco que agrupa informações ou ações sobre um mesmo item.',
    campo:'Campo: local onde a pessoa digita ou escolhe um valor.',
    tabela:'Tabela: lista de dados organizada em linhas e colunas.',
    filtro:'Filtro: restringe os dados exibidos com base em um critério.',
    grafico:'Gráfico: representação visual de dados numéricos.',
    menu:'Menu: lista de opções de navegação ou ações.',
    modal:'Modal: janela que aparece por cima da tela para uma tarefa específica.',
    secao:'Seção: área principal que agrupa um conjunto de conteúdos da tela.',
    lista:'Lista: sequência de itens do mesmo tipo.',
    indicador:'Indicador: número ou métrica que resume uma informação.',
    selo:'Selo: marcador visual curto que indica status ou categoria.',
    texto:'Texto: informação em texto simples, sem ser botão nem campo.'
  };
  // termo em inglês de cada tipo — vocabulário técnico/PM circula muito em inglês
  var TIPO_EN = {
    botao:'button', aba:'tab', card:'card', campo:'field', tabela:'table',
    filtro:'filter', grafico:'chart', menu:'menu', modal:'modal', secao:'section',
    lista:'list', indicador:'indicator / metric', selo:'badge', texto:'text'
  };

  var active=false, gridOn=false;
  var barEl=null, gridEl=null, panelEl=null, highlightEl=null;
  var hoverTimer=null, lastTarget=null;
  var BAR_H=34;
  var pushedEl=null, pushedPrevTop='';

  function pad2(n){ return String(n).padStart(2,'0'); }

  function toHex(colorStr){
    var m = colorStr && colorStr.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?\)/);
    if(!m) return null;
    var a = m[4]!==undefined ? parseFloat(m[4]) : 1;
    if(a===0) return null;
    return '#'+[m[1],m[2],m[3]].map(function(v){ return (+v).toString(16).padStart(2,'0'); }).join('');
  }

  function firstGradientColor(bgImage){
    if(!bgImage || bgImage==='none') return null;
    var m=bgImage.match(/rgba?\([^)]+\)/);
    return m ? toHex(m[0]) : null;
  }

  function effectiveBg(el){
    var node=el;
    while(node && node!==document.documentElement){
      var cs=getComputedStyle(node);
      var hex=toHex(cs.backgroundColor);
      if(hex) return hex;
      var gradHex=firstGradientColor(cs.backgroundImage);
      if(gradHex) return gradHex;
      node=node.parentElement;
    }
    return '#ffffff';
  }
  function effectiveText(el){ return toHex(getComputedStyle(el).color) || '#000000'; }

  function telaAtual(){
    var v=document.querySelector('.view.active');
    if(v && v.id) return v.id.replace(/^view-/,'');
    var gate=document.getElementById('authGate');
    return (gate && gate.style.display!=='none') ? 'login' : '—';
  }

  function tipoDoId(id){ var parts=id.split('.'); return parts[1]||'—'; }

  // Correspondência sempre exata: o identificador só conta quando o mouse está
  // literalmente sobre o elemento marcado, nunca "subindo" a partir de um filho
  // (título, número, badge etc.) para um ancestral com data-id. Cada elemento só
  // responde pelo que é o dele mesmo — o resto aparece como "sem identificador"
  // até ganhar sua própria marcação.
  function elementoMarcado(el){
    return el.hasAttribute('data-id') ? el : null;
  }

  function buildBar(){
    barEl=document.createElement('div');
    barEl.className='fdi-bar';
    barEl.innerHTML =
      '<b>MODO DEV</b>'+
      '<span><span class="fdi-lbl">id</span> <b id="fdiBarId">—</b></span>'+
      '<span><span class="fdi-lbl">tipo</span> <b id="fdiBarTipo">—</b></span>'+
      '<span><span class="fdi-lbl">posição</span> <b id="fdiBarPos">—</b></span>'+
      '<span><span class="fdi-swatch" id="fdiBarTxtSw"></span><span class="fdi-lbl">texto</span> <b id="fdiBarTxt">—</b></span>'+
      '<span><span class="fdi-swatch" id="fdiBarBgSw"></span><span class="fdi-lbl">fundo</span> <b id="fdiBarBg">—</b></span>'+
      '<span class="fdi-spacer"></span>'+
      '<button type="button" id="fdiBtnGrid">Grade</button>'+
      '<button type="button" id="fdiBtnClose">Fechar (F9)</button>';
    document.body.appendChild(barEl);
    document.getElementById('fdiBtnGrid').onclick=toggleGrid;
    document.getElementById('fdiBtnClose').onclick=deactivate;
    syncGridButton();
  }
  function syncGridButton(){
    var b=document.getElementById('fdiBtnGrid');
    if(b) b.classList.toggle('fdi-on', gridOn);
  }

  function buildGrid(){
    gridEl=document.createElement('div');
    gridEl.className='fdi-grid';
    document.body.appendChild(gridEl);
    renderGridLines();
  }
  function renderGridLines(){
    if(!gridEl) return;
    gridEl.style.backgroundImage =
      'repeating-linear-gradient(to right, rgba(234,179,8,.16) 0, rgba(234,179,8,.16) 1px, transparent 1px, transparent '+CELL+'px),'+
      'repeating-linear-gradient(to bottom, rgba(234,179,8,.16) 0, rgba(234,179,8,.16) 1px, transparent 1px, transparent '+CELL+'px)';
  }

  function showHighlight(boxTarget){
    if(!highlightEl){
      highlightEl=document.createElement('div');
      highlightEl.className='fdi-highlight';
      document.body.appendChild(highlightEl);
    }
    var r=boxTarget.getBoundingClientRect();
    highlightEl.style.left=r.left+'px';
    highlightEl.style.top=r.top+'px';
    highlightEl.style.width=r.width+'px';
    highlightEl.style.height=r.height+'px';
  }
  function removeHighlight(){ if(highlightEl){ highlightEl.remove(); highlightEl=null; } }

  function buildPanel(id, refEl, boxTarget, x, y){
    removePanel();
    showHighlight(boxTarget);
    panelEl=document.createElement('div');
    panelEl.className='fdi-panel';
    var tipo = id ? tipoDoId(id) : null;
    var txt=effectiveText(refEl), bg=effectiveBg(refEl);
    var html='';
    if(!id){
      html+='<div class="fdi-warn">sem identificador</div>';
    } else {
      html+='<div class="fdi-row"><span class="fdi-id">'+id+'</span>'+
        '<button type="button" class="fdi-copy" id="fdiCopyBtn">copiar</button></div>'+
        '<div class="fdi-row"><span class="fdi-k">Tipo</span><span class="fdi-v">'+(TIPO_EN[tipo]||tipo)+' <span class="fdi-en">· pt: '+tipo+'</span></span></div>'+
        '<div class="fdi-desc">'+(TIPOS[tipo]||'Tipo não catalogado.')+'</div>';
    }
    html+='<div class="fdi-row" style="margin-top:8px"><span class="fdi-k">Tela</span><span class="fdi-v">'+telaAtual()+'</span></div>'+
      '<div class="fdi-row"><span class="fdi-k">Cor do texto</span><span class="fdi-v"><span class="fdi-swatch" style="background:'+txt+'"></span>'+txt+'</span></div>'+
      '<div class="fdi-row"><span class="fdi-k">Cor de fundo</span><span class="fdi-v"><span class="fdi-swatch" style="background:'+bg+'"></span>'+bg+'</span></div>';
    panelEl.innerHTML=html;
    document.body.appendChild(panelEl);
    if(id){
      var copyBtn=document.getElementById('fdiCopyBtn');
      copyBtn.onclick=function(){
        var done=function(){ copyBtn.textContent='copiado!'; setTimeout(function(){ if(copyBtn) copyBtn.textContent='copiar'; },1200); };
        var fail=function(){ copyBtn.textContent='falhou'; setTimeout(function(){ if(copyBtn) copyBtn.textContent='copiar'; },1200); };
        if(navigator.clipboard && navigator.clipboard.writeText){
          navigator.clipboard.writeText(id).then(done, fail);
        } else fail();
      };
    }
    var pw=280, ph=panelEl.offsetHeight||160;
    var left=Math.max(10, Math.min(x+16, window.innerWidth-pw-10));
    var top=Math.max(10, Math.min(y+16, window.innerHeight-ph-10));
    panelEl.style.left=left+'px';
    panelEl.style.top=top+'px';
  }
  function removePanel(){ if(panelEl){ panelEl.remove(); panelEl=null; } removeHighlight(); }

  function onMouseMove(e){
    if(barEl && e.clientY<=barEl.offsetHeight) return;
    if(panelEl && panelEl.contains(e.target)) return;
    var el=document.elementFromPoint(e.clientX,e.clientY);
    if(!el) return;
    var tagged=elementoMarcado(el);
    var id=tagged?tagged.getAttribute('data-id'):null;

    var col=Math.floor(e.clientX/CELL)+1, row=Math.floor(e.clientY/CELL)+1;
    document.getElementById('fdiBarId').textContent=id||'—';
    document.getElementById('fdiBarTipo').textContent=id?tipoDoId(id):'—';
    document.getElementById('fdiBarPos').textContent='R'+pad2(row)+'C'+pad2(col);
    var txt=effectiveText(el), bg=effectiveBg(el);
    document.getElementById('fdiBarTxt').textContent=txt;
    document.getElementById('fdiBarBg').textContent=bg;
    document.getElementById('fdiBarTxtSw').style.background=txt;
    document.getElementById('fdiBarBgSw').style.background=bg;

    var target=tagged||el;
    if(target!==lastTarget){
      lastTarget=target;
      removePanel();
      clearTimeout(hoverTimer);
      var mx=e.clientX, my=e.clientY, refEl=el, boxTarget=target;
      hoverTimer=setTimeout(function(){ buildPanel(id, refEl, boxTarget, mx, my); }, 2000);
    }
  }

  function onResize(){ renderGridLines(); }

  function toggleGrid(){
    gridOn=!gridOn;
    syncGridButton();
    if(gridOn && !gridEl) buildGrid();
    else if(!gridOn && gridEl){ gridEl.remove(); gridEl=null; }
  }

  function pushSiteDown(){
    document.body.style.marginTop=BAR_H+'px';
    pushedEl=document.querySelector('.topbar');
    if(pushedEl){ pushedPrevTop=pushedEl.style.top; pushedEl.style.top=BAR_H+'px'; }
  }
  function unpushSiteDown(){
    document.body.style.marginTop='';
    if(pushedEl){ pushedEl.style.top=pushedPrevTop; pushedEl=null; }
  }

  function activate(){
    if(active) return;
    active=true;
    buildBar();
    pushSiteDown();
    if(gridOn) buildGrid();
    document.addEventListener('mousemove', onMouseMove);
    window.addEventListener('resize', onResize);
  }
  function deactivate(){
    if(!active) return;
    active=false;
    document.removeEventListener('mousemove', onMouseMove);
    window.removeEventListener('resize', onResize);
    clearTimeout(hoverTimer);
    lastTarget=null;
    removePanel();
    unpushSiteDown();
    if(barEl){ barEl.remove(); barEl=null; }
    if(gridEl){ gridEl.remove(); gridEl=null; }
  }

  document.addEventListener('keydown', function(e){
    if(e.key==='F9'){ e.preventDefault(); active?deactivate():activate(); }
  });
})();
