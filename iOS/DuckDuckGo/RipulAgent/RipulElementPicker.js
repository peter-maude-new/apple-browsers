// RipulElementPicker.js
// ---------------------
// Function body executed via WKWebView.callAsyncJavaScript().
// Creates an interactive element picker overlay on the page.
// Returns a Promise that resolves with { selector, html } or { cancelled: true }.

return new Promise(function(resolve) {
    var overlay = document.createElement('div');
    overlay.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;z-index:2147483646;cursor:crosshair;';

    var highlight = document.createElement('div');
    highlight.style.cssText = 'position:fixed;pointer-events:none;z-index:2147483647;border:2px solid #4CAF50;background:rgba(76,175,80,0.15);border-radius:3px;transition:all 0.05s ease;display:none;';
    document.body.appendChild(highlight);

    var tooltip = document.createElement('div');
    tooltip.style.cssText = 'position:fixed;z-index:2147483647;pointer-events:none;background:#333;color:#fff;padding:4px 8px;border-radius:4px;font:12px/1.4 -apple-system,sans-serif;max-width:300px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;display:none;';
    document.body.appendChild(tooltip);

    var cancelBtn = document.createElement('div');
    cancelBtn.textContent = 'Cancel';
    cancelBtn.style.cssText = 'position:fixed;top:env(safe-area-inset-top,12px);right:12px;z-index:2147483647;background:#ff3b30;color:#fff;padding:8px 16px;border-radius:20px;font:600 14px/1.2 -apple-system,sans-serif;cursor:pointer;margin-top:12px;';
    document.body.appendChild(cancelBtn);

    var lastTarget = null;

    function genSelector(el) {
        if (el.id) return '#' + CSS.escape(el.id);
        var path = [];
        while (el && el !== document.body && el !== document.documentElement) {
            var tag = el.tagName.toLowerCase();
            var parent = el.parentElement;
            if (parent) {
                var siblings = Array.from(parent.children).filter(function(c) { return c.tagName === el.tagName; });
                if (siblings.length > 1) tag += ':nth-of-type(' + (siblings.indexOf(el) + 1) + ')';
            }
            path.unshift(tag);
            el = parent;
        }
        return path.join(' > ');
    }

    function getElementUnder(x, y) {
        overlay.style.pointerEvents = 'none';
        var el = document.elementFromPoint(x, y);
        overlay.style.pointerEvents = '';
        return el;
    }

    function updateHighlight(el) {
        if (!el || el === document.body || el === document.documentElement) {
            highlight.style.display = 'none';
            tooltip.style.display = 'none';
            return;
        }
        var r = el.getBoundingClientRect();
        highlight.style.left = r.left + 'px';
        highlight.style.top = r.top + 'px';
        highlight.style.width = r.width + 'px';
        highlight.style.height = r.height + 'px';
        highlight.style.display = 'block';
        tooltip.textContent = el.tagName.toLowerCase() + (el.className ? '.' + String(el.className).split(' ')[0] : '');
        tooltip.style.left = Math.min(r.left, window.innerWidth - 310) + 'px';
        tooltip.style.top = Math.max(0, r.top - 30) + 'px';
        tooltip.style.display = 'block';
    }

    function cleanup() { overlay.remove(); highlight.remove(); tooltip.remove(); cancelBtn.remove(); }

    function pick() {
        var selector = genSelector(lastTarget);
        var html = lastTarget.outerHTML;
        if (html.length > 5000) html = html.substring(0, 5000) + '...';
        cleanup();
        resolve({ selector: selector, html: html });
    }

    overlay.addEventListener('touchmove', function(e) {
        e.preventDefault();
        var t = e.touches[0];
        var el = getElementUnder(t.clientX, t.clientY);
        if (el && el !== lastTarget) { lastTarget = el; updateHighlight(el); }
    }, { passive: false });

    overlay.addEventListener('touchend', function(e) {
        e.preventDefault();
        if (lastTarget && lastTarget !== document.body) pick();
    });

    overlay.addEventListener('mousemove', function(e) {
        var el = getElementUnder(e.clientX, e.clientY);
        if (el && el !== lastTarget) { lastTarget = el; updateHighlight(el); }
    });

    overlay.addEventListener('click', function(e) {
        e.preventDefault(); e.stopPropagation();
        if (lastTarget && lastTarget !== document.body) pick();
    });

    cancelBtn.addEventListener('click', function(e) { e.stopPropagation(); cleanup(); resolve({ cancelled: true }); });
    cancelBtn.addEventListener('touchend', function(e) { e.preventDefault(); e.stopPropagation(); cleanup(); resolve({ cancelled: true }); });

    document.body.appendChild(overlay);
});
