/* =====================================================================
   Dicionário de Dados - Sistema de Gestão Operacional Pizzaria
   Interações: tema claro/escuro, navegação lateral dinâmica, pesquisa em
   tempo real, modal do DER (zoom e arraste) e modal do DDL (cópia e realce).
   ===================================================================== */
(function () {
  'use strict';

  var $ = function (sel, root) { return (root || document).querySelector(sel); };
  var $$ = function (sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); };

  /* ---------------- 1. Tema claro / escuro ---------------- */
  var root = document.documentElement;
  var themeToggle = $('#themeToggle');
  var themeLabel = $('#themeLabel');

  function applyTheme(theme) {
    root.setAttribute('data-theme', theme);
    themeToggle.setAttribute('aria-pressed', theme === 'dark' ? 'true' : 'false');
    themeLabel.textContent = theme === 'dark' ? 'Modo claro' : 'Modo escuro';
    try { localStorage.setItem('dd-theme', theme); } catch (e) { /* armazenamento indisponível */ }
  }
  applyTheme(root.getAttribute('data-theme') === 'dark' ? 'dark' : 'light');
  themeToggle.addEventListener('click', function () {
    applyTheme(root.getAttribute('data-theme') === 'dark' ? 'light' : 'dark');
  });

  /* ---------------- 2. Sidebar gerada a partir das seções ---------------- */
  var sections = $$('.dict-table');
  var navTables = $('#navTables');
  var navLinks = {};

  (function buildNav() {
    var currentDomain = null, list = null;
    sections.forEach(function (sec) {
      var domain = sec.getAttribute('data-domain');
      if (domain !== currentDomain) {
        var h = document.createElement('p');
        h.className = 'nav-domain';
        h.textContent = domain;
        navTables.appendChild(h);
        list = document.createElement('ul');
        list.className = 'nav-list';
        navTables.appendChild(list);
        currentDomain = domain;
      }
      var name = sec.getAttribute('data-table');
      var li = document.createElement('li');
      var a = document.createElement('a');
      a.href = '#' + name;
      var code = document.createElement('code');
      code.textContent = name;
      var n = document.createElement('span');
      n.className = 'n';
      n.textContent = $$('tbody tr', sec).length;
      a.appendChild(code); a.appendChild(n);
      li.appendChild(a); list.appendChild(li);
      navLinks[name] = { li: li, a: a };
    });
    $('#navTotal').textContent = sections.length;
  })();

  /* menu no celular */
  var sidebar = $('#sidebar');
  var backdrop = $('#backdrop');
  var menuToggle = $('#menuToggle');
  function setMenu(open) {
    sidebar.classList.toggle('is-open', open);
    backdrop.hidden = !open;
    menuToggle.setAttribute('aria-expanded', open ? 'true' : 'false');
  }
  menuToggle.addEventListener('click', function () { setMenu(!sidebar.classList.contains('is-open')); });
  backdrop.addEventListener('click', function () { setMenu(false); });
  sidebar.addEventListener('click', function (ev) { if (ev.target.closest('a')) setMenu(false); });

  /* destaque da tabela visível */
  if ('IntersectionObserver' in window) {
    var visible = {};
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) { visible[en.target.id] = en.isIntersecting; });
      var current = null;
      for (var i = 0; i < sections.length; i++) { if (visible[sections[i].id]) { current = sections[i].id; break; } }
      Object.keys(navLinks).forEach(function (k) { navLinks[k].a.classList.toggle('active', k === current); });
      if (current && window.innerWidth > 860) {
        var el = navLinks[current].a, top = el.offsetTop, sb = sidebar;
        if (top < sb.scrollTop + 60 || top > sb.scrollTop + sb.clientHeight - 60) sb.scrollTop = top - sb.clientHeight / 2;
      }
    }, { rootMargin: '-160px 0px -50% 0px' });
    sections.forEach(function (s) { io.observe(s); });
  }

  /* compensa a barra superior e o painel fixo ao navegar pelas âncoras */
  var controlPanel = $('#controle');
  function setStickyOffset() {
    var topbar = $('.topbar').offsetHeight;
    var fixed = getComputedStyle(controlPanel).position === 'sticky' ? controlPanel.offsetHeight : 0;
    root.style.setProperty('--sticky-offset', (topbar + fixed + 14) + 'px');
  }
  setStickyOffset();
  window.addEventListener('resize', setStickyOffset);

  /* ---------------- 3. Pesquisa em tempo real ---------------- */
  var search = $('#search');
  var statusEl = $('#searchStatus');
  var emptyState = $('#emptyState');

  function norm(s) { return s.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, ''); }

  var index = sections.map(function (sec) {
    return {
      sec: sec,
      name: sec.getAttribute('data-table'),
      title: $('.dt-title', sec),
      rows: $$('tbody tr', sec).map(function (tr) {
        return { tr: tr, col: tr.getAttribute('data-col'), code: $('.c-attr code', tr) };
      })
    };
  });

  function paint(el, text, q) {
    var i = q ? norm(text).indexOf(q) : -1;
    var icon = el.querySelector('.dt-icon');
    el.textContent = '';
    if (icon) el.appendChild(icon);
    if (i < 0) { el.appendChild(document.createTextNode(text)); return; }
    el.appendChild(document.createTextNode(text.slice(0, i)));
    var m = document.createElement('mark');
    m.textContent = text.slice(i, i + q.length);
    el.appendChild(m);
    el.appendChild(document.createTextNode(text.slice(i + q.length)));
  }

  function filter() {
    var q = norm(search.value.trim());
    var nTables = 0, nCols = 0;
    index.forEach(function (t) {
      var tableHit = q && norm(t.name).indexOf(q) >= 0;
      var shown = 0;
      t.rows.forEach(function (r) {
        var hit = !q || tableHit || norm(r.col).indexOf(q) >= 0;
        r.tr.classList.toggle('is-hidden', !hit);
        paint(r.code, r.col, q);
        if (hit) shown++;
      });
      var show = !q || tableHit || shown > 0;
      t.sec.classList.toggle('is-hidden', !show);
      navLinks[t.name].li.classList.toggle('is-hidden', !show);
      paint(t.title, t.name, q);
      if (show) { nTables++; nCols += shown; }
    });
    emptyState.hidden = nTables > 0;
    statusEl.innerHTML = q
      ? 'Mostrando <b>' + nTables + '</b> ' + (nTables === 1 ? 'tabela' : 'tabelas') + ' e <b>' + nCols + '</b> ' + (nCols === 1 ? 'atributo' : 'atributos') + ' para "' + search.value.trim().replace(/[<>&]/g, '') + '"'
      : '';
  }
  search.addEventListener('input', filter);
  $('#clearSearch').addEventListener('click', function () { search.value = ''; filter(); search.focus(); });
  document.addEventListener('keydown', function (ev) {
    if (ev.key === '/' && document.activeElement !== search && !document.body.classList.contains('modal-open')) {
      ev.preventDefault(); search.focus(); search.select();
    }
  });

  /* ---------------- 4. Modais ---------------- */
  var lastFocus = null;
  function openModal(id) {
    var modal = document.getElementById(id);
    lastFocus = document.activeElement;
    modal.hidden = false;
    document.body.classList.add('modal-open');
    var closeBtn = $('[data-close]', modal);
    if (closeBtn) closeBtn.focus();
    if (id === 'modalDer') derOpen();
    if (id === 'modalDdl') ddlOpen();
  }
  function closeModal(modal) {
    modal.hidden = true;
    if (!$$('.modal').some(function (m) { return !m.hidden; })) document.body.classList.remove('modal-open');
    if (lastFocus && lastFocus.focus) lastFocus.focus();
  }
  $$('[data-open]').forEach(function (b) { b.addEventListener('click', function () { openModal(b.getAttribute('data-open')); }); });
  $$('.modal').forEach(function (modal) {
    modal.addEventListener('click', function (ev) {
      if (ev.target === modal || ev.target.closest('[data-close]')) closeModal(modal);
    });
  });
  document.addEventListener('keydown', function (ev) {
    if (ev.key !== 'Escape') return;
    var open = $$('.modal').filter(function (m) { return !m.hidden; })[0];
    if (open) closeModal(open); else setMenu(false);
  });

  /* ---------------- 5. DER: zoom com scroll, arraste e botões ---------------- */
  var viewport = $('#derViewport');
  var img = $('#derImage');
  var zoomLevel = $('#zoomLevel');
  var view = { scale: 1, x: 0, y: 0, fit: 1 };
  var MIN_FACTOR = 0.5, MAX_SCALE = 6;

  function derRender() {
    img.style.transform = 'translate(' + view.x + 'px,' + view.y + 'px) scale(' + view.scale + ')';
    zoomLevel.textContent = Math.round((view.scale / view.fit) * 100) + '%';
  }
  function derReset() {
    var vw = viewport.clientWidth, vh = viewport.clientHeight;
    var iw = img.naturalWidth || 1, ih = img.naturalHeight || 1;
    view.fit = Math.min(vw / iw, vh / ih);
    view.scale = view.fit;
    view.x = (vw - iw * view.scale) / 2;
    view.y = (vh - ih * view.scale) / 2;
    derRender();
  }
  function derZoom(factor, cx, cy) {
    var next = Math.min(MAX_SCALE, Math.max(view.fit * MIN_FACTOR, view.scale * factor));
    if (cx === undefined) { cx = viewport.clientWidth / 2; cy = viewport.clientHeight / 2; }
    var k = next / view.scale;
    view.x = cx - (cx - view.x) * k;
    view.y = cy - (cy - view.y) * k;
    view.scale = next;
    derRender();
  }
  function derOpen() {
    if (img.complete && img.naturalWidth) derReset();
    else img.addEventListener('load', derReset, { once: true });
  }
  viewport.addEventListener('wheel', function (ev) {
    ev.preventDefault();
    var r = viewport.getBoundingClientRect();
    derZoom(ev.deltaY < 0 ? 1.15 : 1 / 1.15, ev.clientX - r.left, ev.clientY - r.top);
  }, { passive: false });

  var pointers = {}, lastDist = 0;
  viewport.addEventListener('pointerdown', function (ev) {
    viewport.setPointerCapture(ev.pointerId);
    pointers[ev.pointerId] = { x: ev.clientX, y: ev.clientY };
    viewport.classList.add('is-dragging');
  });
  viewport.addEventListener('pointermove', function (ev) {
    var p = pointers[ev.pointerId];
    if (!p) return;
    var ids = Object.keys(pointers);
    if (ids.length === 1) {
      view.x += ev.clientX - p.x; view.y += ev.clientY - p.y;
      derRender();
    }
    p.x = ev.clientX; p.y = ev.clientY;
    if (ids.length === 2) {
      var a = pointers[ids[0]], b = pointers[ids[1]];
      var dist = Math.hypot(a.x - b.x, a.y - b.y);
      var r = viewport.getBoundingClientRect();
      if (lastDist) derZoom(dist / lastDist, (a.x + b.x) / 2 - r.left, (a.y + b.y) / 2 - r.top);
      lastDist = dist;
    }
  });
  function pointerEnd(ev) {
    delete pointers[ev.pointerId];
    lastDist = 0;
    if (!Object.keys(pointers).length) viewport.classList.remove('is-dragging');
  }
  viewport.addEventListener('pointerup', pointerEnd);
  viewport.addEventListener('pointercancel', pointerEnd);
  viewport.addEventListener('dblclick', function (ev) {
    var r = viewport.getBoundingClientRect();
    derZoom(1.6, ev.clientX - r.left, ev.clientY - r.top);
  });
  $('#zoomIn').addEventListener('click', function () { derZoom(1.25); });
  $('#zoomOut').addEventListener('click', function () { derZoom(1 / 1.25); });
  $('#zoomReset').addEventListener('click', derReset);
  window.addEventListener('resize', function () { if (!$('#modalDer').hidden) derReset(); });
  document.addEventListener('keydown', function (ev) {
    if ($('#modalDer').hidden) return;
    if (ev.key === '+' || ev.key === '=') derZoom(1.25);
    else if (ev.key === '-') derZoom(1 / 1.25);
    else if (ev.key === '0') derReset();
  });

  /* ---------------- 6. DDL: realce de sintaxe, linhas e cópia ---------------- */
  var ddlCode = $('#ddlCode');
  var ddlPre = $('#ddlPre');
  var DDL_TEXT = ddlCode.textContent;
  var ddlReady = false;

  function fallbackHighlight() {
    /* Usado somente se o Prism.js (CDN) não carregar: mantém números de linha e cores básicas. */
    var KEY = /\b(CREATE|TABLE|SCHEMA|IF|NOT|EXISTS|NULL|DEFAULT|PRIMARY|KEY|FOREIGN|REFERENCES|CONSTRAINT|UNIQUE|INDEX|CHECK|ON|DELETE|UPDATE|RESTRICT|DROP|USE|SET|ENGINE|CHARACTER|COLLATE|AUTO_INCREMENT|GENERATED|ALWAYS|AS|STORED|COMMENT|AND|OR|IN|ASC|VISIBLE|CAST)\b/g;
    var TYPE = /\b(INT|VARCHAR|CHAR|DECIMAL|TEXT|DATETIME|DATE|TINYINT|BOOLEAN|ENUM|TRUE|FALSE|CURRENT_TIMESTAMP)\b/g;
    function escHtml(s) { return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }
    var lines = DDL_TEXT.split('\n');
    var html = lines.map(function (line) {
      if (/^\s*--/.test(line)) return '<span class="fb-c">' + escHtml(line) + '</span>';
      return line.split(/('[^']*'|`[^`]*`)/).map(function (part) {
        if (part.charAt(0) === "'") return '<span class="fb-s">' + escHtml(part) + '</span>';
        if (part.charAt(0) === '`') return '<span class="fb-i">' + escHtml(part) + '</span>';
        return escHtml(part).replace(KEY, '<span class="fb-k">$1</span>').replace(TYPE, '<span class="fb-t">$1</span>')
          .replace(/\b(\d+(?:\.\d+)?)\b/g, '<span class="fb-n">$1</span>');
      }).join('');
    }).join('\n');
    var gutter = document.createElement('span');
    gutter.className = 'fb-gutter';
    gutter.setAttribute('aria-hidden', 'true');
    gutter.textContent = lines.map(function (_, i) { return i + 1; }).join('\n');
    ddlCode.innerHTML = html;
    ddlPre.classList.remove('line-numbers');
    ddlPre.classList.add('fb-lines');
    ddlPre.insertBefore(gutter, ddlCode);
  }

  function ddlOpen() {
    if (ddlReady) return;
    ddlReady = true;
    if (window.Prism && Prism.languages && Prism.languages.sql) {
      Prism.highlightElement(ddlCode); /* o plugin line-numbers numera as linhas após o realce */
    } else {
      fallbackHighlight();
    }
  }
  if (window.Prism) Prism.manual = true;

  var copyBtn = $('#copyDdl');
  var copyLabel = $('#copyLabel');
  function copied(ok) {
    copyLabel.textContent = ok ? 'Copiado!' : 'Não foi possível copiar';
    copyBtn.classList.toggle('is-copied', ok);
    setTimeout(function () { copyLabel.textContent = 'Copiar DDL'; copyBtn.classList.remove('is-copied'); }, 2000);
  }
  function legacyCopy() {
    var ta = document.createElement('textarea');
    ta.value = DDL_TEXT; ta.setAttribute('readonly', '');
    ta.style.position = 'fixed'; ta.style.opacity = '0';
    document.body.appendChild(ta); ta.select();
    var ok = false;
    try { ok = document.execCommand('copy'); } catch (e) { ok = false; }
    document.body.removeChild(ta);
    copied(ok);
  }
  copyBtn.addEventListener('click', function () {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(DDL_TEXT).then(function () { copied(true); }, legacyCopy);
    } else {
      legacyCopy();
    }
  });
})();
