/* 信徒管理 — 本機資料層（單一快照 sm.data.v1，由 sync.js 加密同步）
   集合：people 人員｜seats 會座｜yearly 年度申請與收費（id=年度:人員id）｜config 設定 */
(function (g) {
  'use strict';
  var KEY = 'sm.data.v1', COLS = ['people', 'seats', 'yearly', 'config'];
  var OK = (function () { try { localStorage.setItem('__p', '1'); localStorage.removeItem('__p'); return true; } catch (e) { return false; } })();
  var iso = function () { return new Date().toISOString(); };
  var mem = null;
  function read() {
    var d = null;
    if (OK) { try { d = JSON.parse(localStorage.getItem(KEY) || 'null'); } catch (e) {} } else d = mem;
    if (!d || typeof d !== 'object') d = {};
    if (!d.deleted) d.deleted = {};
    COLS.forEach(function (c) { if (!Array.isArray(d[c])) d[c] = []; });
    return d;
  }
  function write(d) {
    if (!OK) { mem = d; return true; }
    try { localStorage.setItem(KEY, JSON.stringify(d)); return true; } catch (e) { return false; }
  }
  function sched() { if (g.SMSync) g.SMSync.schedule(1200); }
  function all(c) { return read()[c] || []; }
  function get(c, id) { return all(c).find(function (x) { return x.id === id; }) || null; }
  /* 批次寫入：docs 逐筆補 updatedAt，一次存檔 */
  function putMany(c, docs, delIds) {
    var d = read(), t = iso(), m = {};
    d[c].forEach(function (x) { m[x.id] = x; });
    docs.forEach(function (x) { if (x && x.id) { m[x.id] = Object.assign({}, x, { updatedAt: t }); delete d.deleted[c + ':' + x.id]; } });
    (delIds || []).forEach(function (id) { delete m[id]; d.deleted[c + ':' + id] = t; });
    d[c] = Object.keys(m).map(function (k) { return m[k]; });
    var ok = write(d); if (ok) sched(); return ok;
  }
  function put(c, doc) { return putMany(c, [doc]); }
  function del(c, id) { return putMany(c, [], [id]); }
  function attach(onChange, toast) {
    if (!g.SMSync) return false;
    g.SMSync.init({ cols: COLS, readLocal: read, writeLocal: write, onChange: onChange, toast: toast });
    return true;
  }
  g.SMStore = { COLS: COLS, KEY: KEY, available: OK, read: read, write: write, all: all, get: get, put: put, putMany: putMany, del: del, attach: attach };
})(window);
