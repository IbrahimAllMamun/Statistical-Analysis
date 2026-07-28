/* ============================================================================
   Litigation Dashboard - static client-side JS
   ----------------------------------------------------------------------------
   Loaded once by litigation_dashboard.RMD. Contains everything that does NOT
   depend on R interpolation:
     - navbar report-date label
     - lazy detail-payload inflation (gzip + base64 -> objects)
     - renderCaseDetails() and its HTML builders
     - downloadFiltered() CSV export + EXPORT_COLS layout

   R still injects two small data-only <script> tags BEFORE this file loads:
     window.__LIT_PAYLOAD_B64   (the base64 detail payload)
     window.__LIT_REPORT_DATE   (the report date string)

   The per-tab filter JS (updateCifOptions, clearAllFilters, initFilters, ...)
   is generated per-suffix by render_filter_panel() in helpers.R and therefore
   stays there - it cannot be static because each tab needs uniquely named
   copies.
   ============================================================================ */

/* ---- navbar report-date label ---- */
document.addEventListener('DOMContentLoaded', function () {
  var navbar = document.querySelector('.navbar-nav.navbar-right')
            || document.querySelector('.navbar-collapse')
            || document.querySelector('.navbar');
  if (navbar && window.__LIT_REPORT_DATE) {
    var item = document.createElement('span');
    item.className = 'navbar-text';
    item.style = 'color:#fff; margin-right:16px; font-weight:600;';
    item.textContent = 'Report Date: ' + window.__LIT_REPORT_DATE;
    navbar.appendChild(item);
  }
});

/* ---- lazy detail payload + case-details rendering ---- */
(function () {
  // inflate the embedded (gzip + base64) detail payload once
  window.detailsByCase = {};
  window.historyByCase = {};
  window.__litReady = false;
  window.__litError = false;

  (async function () {
    try {
      var b64 = window.__LIT_PAYLOAD_B64 || '';
      var bin = atob(b64);
      var bytes = new Uint8Array(bin.length);
      for (var i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
      // R's memCompress(type='gzip') emits a zlib (RFC 1950) stream,
      // which the Compression Streams API calls 'deflate' (not 'gzip').
      var ds = new DecompressionStream('deflate');
      var stream = new Blob([bytes]).stream().pipeThrough(ds);
      var buf = await new Response(stream).arrayBuffer();
      var obj = JSON.parse(new TextDecoder('utf-8').decode(buf));
      window.detailsByCase = obj.details || {};
      window.historyByCase = obj.history || {};
      window.__litReady = true;
      window.__LIT_PAYLOAD_B64 = null; // release the base64 string from memory
    } catch (e) {
      console.error('Litigation dashboard: failed to load detail payload.', e);
      window.__litError = true;
    }
  })();

  var CI_LABELS = ['Nature of Suit', 'Suit Value', 'Suit Filing Date', 'Law Firm',
    'Court No', 'Next Hearing Date', 'Cheque Number', 'Litigation Receivable', 'Present Case Status', 'Active Status'];
  var AI_LABELS = ['RM Name', 'Product Category', 'URPA', 'Overdue Amount', 'Principal OD', 'Interest OD', 'MOD', 'LPI',
    'Net Excise Duty (Last Year)', 'Net Excise Duty (Current Year)'];

  window.CI_LABELS = CI_LABELS;
  window.AI_LABELS = AI_LABELS;

  function esc(s) {
    return String(s == null ? '\u2014' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  function field(label, value, accent) {
    var cls = 'case-detail-field' + (accent ? ' ' + accent : '');
    return '<div class="' + cls + '">' +
             '<div class="case-detail-label">' + esc(label) + '</div>' +
             '<div class="case-detail-value">' + esc(value) + '</div>' +
           '</div>';
  }

  function section(title, inner) {
    return '<div class="case-detail-section">' +
             '<div class="case-detail-section-title">' + esc(title) + '</div>' +
             '<div class="case-detail-grid">' + inner + '</div>' +
           '</div>';
  }

  function historyTable(rows) {
    if (!rows || !rows.length) return '';
    var body = rows.map(function (r) {
      var dur = (r.a == null)
        ? '\u2014'
        : '<span class="aging-pill ' + r.ac + '">' + r.a + ' days</span>';
      return '<tr>' +
               '<td>' + esc(r.d) + '</td>' +
               '<td><span class="status-pill ' + r.sc + '">' + esc(r.s) + '</span></td>' +
               '<td>' + dur + '</td>' +
             '</tr>';
    }).join('');
    return '<div class="history-table-wrap">' +
             '<div class="history-table-caption">Case History</div>' +
             '<table class="history-mini">' +
               '<thead><tr><th>Hearing Date</th><th>Case Status</th><th>Duration</th></tr></thead>' +
               '<tbody>' + body + '</tbody>' +
             '</table>' +
           '</div>';
  }

  window.renderCaseDetails = function (caseId) {
    if (window.__litError) return '<div class="case-detail-panel">Case details could not be loaded (this browser may not support in-page decompression).</div>';
    if (!window.__litReady) return '<div class="case-detail-panel">Loading case details\u2026</div>';
    var d = (window.detailsByCase || {})[caseId];
    var h = (window.historyByCase || {})[caseId] || [];
    if (!d) return '<div class="case-detail-panel">No details available.</div>';

    var ci = CI_LABELS.map(function (lbl, i) {
      var accent = null;
      if (i === CI_LABELS.length - 1) {
        accent = d.acc;                      // Active Status (last)
      } else if (i === CI_LABELS.length - 2) {
        accent = 'card-present-status';      // Present Status (second to last)
      }
      return field(lbl, d.ci[i], accent);
    }).join('');

    var ai = AI_LABELS.map(function (lbl, i) {
      return field(lbl, d.ai[i]);
    }).join('');

    return '<div class="case-detail-panel">' +
             section('Case Info', ci) +
             section('Account Info', ai) +
             historyTable(h) +
           '</div>';
  };
})();

/* ---- CSV export of the currently-filtered table ---- */
(function () {
  // Explicit export layout: [Header, source, key]
  //   source 'main' -> column on the reactable row
  //   source 'ci'   -> index into detailsByCase[caseId].ci
  //   source 'ai'   -> index into detailsByCase[caseId].ai
  var EXPORT_COLS = [
    ['ClientName',                     'main', 'ClientName'],
    ['CIF',                            'main', 'CIF'],
    ['AccountNumber',                  'main', 'AccountNumber'],
    ['CaseID',                         'main', 'CaseID'],
    ['Branch',                         'main', 'Branch'],
    ['LitigationStatus',               'main', 'LitigationStatus'],
    ['Product Category',               'ai',   1],
    ['Nature of Suit',                 'ci',   0],
    ['Court No',                       'ci',   4],
    ['Law Firm',                       'ci',   3],
    ['Cheque Number',                  'ci',   6],
    ['Suit Filing Date',               'ci',   2],
    ['Suit Value',                     'ci',   1],
    ['Litigation Receivable',          'ci',   7],
    ['Next Hearing Date',              'ci',   5],
    ['Present Case Status',            'ci',   8],
    ['RM Name',                        'ai',   0],
    ['URPA',                           'ai',   2],
    ['Overdue Amount',                 'ai',   3],
    ['Principal OD',                   'ai',   4],
    ['Interest OD',                    'ai',   5],
    ['MOD',                            'ai',   6],
    ['LPI',                            'ai',   7],
    ['Net Excise Duty (Last Year)',    'ai',   8],
    ['Net Excise Duty (Current Year)', 'ai',   9]
  ];

  window.downloadFiltered = function (tableId, filename) {
    if (!window.__litReady) { alert('Case details still loading - try again in a moment.'); return; }
    var state = Reactable.getState(tableId);
    var src = state.sortedData || state.data || [];

    function flatten(rows, out) {
      rows.forEach(function (r) {
        if (r._subRows && r._subRows.length) flatten(r._subRows, out);
        else out.push(r);
      });
      return out;
    }
    var rows = flatten(src, []);
    if (!rows.length) { alert('No rows to export.'); return; }

    var DQ = String.fromCharCode(34);
    var esc = function (v) {
      var s = (v == null ? '' : String(v));
      s = s.split(DQ).join(DQ + DQ);
      if (s.indexOf(DQ) !== -1 || s.indexOf(',') !== -1 || s.indexOf('\n') !== -1) {
        return DQ + s + DQ;
      }
      return s;
    };

    var lines = [EXPORT_COLS.map(function (c) { return esc(c[0]); }).join(',')];

    rows.forEach(function (r) {
      var d = (window.detailsByCase || {})[String(r['CaseID'])] || {};
      var ci = d.ci || [];
      var ai = d.ai || [];
      var line = EXPORT_COLS.map(function (c) {
        if (c[1] === 'main') return r[c[2]];
        if (c[1] === 'ci')   return ci[c[2]];
        return ai[c[2]];
      });
      lines.push(line.map(esc).join(','));
    });

    var blob = new Blob(['\uFEFF' + lines.join('\n')], { type: 'text/csv;charset=utf-8;' });
    var a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = filename || 'export.csv';
    a.click();
    URL.revokeObjectURL(a.href);
  };
})();