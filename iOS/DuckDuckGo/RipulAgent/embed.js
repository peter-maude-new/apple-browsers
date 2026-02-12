"use strict";var AgentFramework=(()=>{var q=Object.defineProperty;var he=Object.getOwnPropertyDescriptor;var me=Object.getOwnPropertyNames;var ue=Object.prototype.hasOwnProperty;var fe=(o,e,t)=>e in o?q(o,e,{enumerable:!0,configurable:!0,writable:!0,value:t}):o[e]=t;var pe=(o,e)=>{for(var t in e)q(o,t,{get:e[t],enumerable:!0})},be=(o,e,t,i)=>{if(e&&typeof e=="object"||typeof e=="function")for(let n of me(e))!ue.call(o,n)&&n!==t&&q(o,n,{get:()=>e[n],enumerable:!(i=he(e,n))||i.enumerable});return o};var ye=o=>be(q({},"__esModule",{value:!0}),o);var d=(o,e,t)=>fe(o,typeof e!="symbol"?e+"":e,t);var ze={};pe(ze,{DataAttributeConfigProvider:()=>C,EmbedManager:()=>T,StaticConfigProvider:()=>_,createEmbedInstance:()=>ge,destroy:()=>Le,destroyAgentFramework:()=>D,getAPI:()=>Ae,getAgentFrameworkAPI:()=>F,getAgentFrameworkInfo:()=>ce,init:()=>Pe,initAgentFramework:()=>L,isAgentFrameworkInitialized:()=>de,normalizeConfig:()=>U,parseDataAttributes:()=>j});var G="1.0.0",E="agent-framework:";function O(o){return typeof o=="object"&&o!==null&&"type"in o&&typeof o.type=="string"&&o.type.startsWith(E)}function x(o,e={}){return{type:`${E}${o}`,version:G,timestamp:Date.now(),...e}}var J={overlayId:"chrome-extension-element-picker-overlay",highlightId:"chrome-extension-element-picker-highlight",tooltipId:"chrome-extension-element-picker-tooltip",selectedClass:"chrome-extension-element-selected",controlPanelId:"chrome-extension-element-picker-controls",multiSelect:!1};function ve(o){let e="chrome-extension-picker-styles",t=document.getElementById(e);t&&t.remove();let i=document.createElement("style");i.id=e,i.textContent=`
    .${o} {
      outline: 3px solid #4CAF50 !important;
      outline-offset: 1px !important;
      background-color: rgba(76, 175, 80, 0.1) !important;
      position: relative !important;
    }
    
    .${o}::after {
      content: "\u2713";
      position: absolute;
      top: 2px;
      right: 2px;
      background: #4CAF50;
      color: white;
      width: 20px;
      height: 20px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 14px;
      font-weight: bold;
      z-index: 2147483647;
      pointer-events: none;
    }
  `,document.head.appendChild(i)}function Z(o={}){let e={...J,...o};console.log("[ElementPicker] Starting element picker",{multiSelect:e.multiSelect}),I(e),e.multiSelect&&ve(e.selectedClass);let t=we(e.overlayId),i=Ee(e.highlightId),n=xe(e.tooltipId),r=null;e.multiSelect&&(r=ke(e.controlPanelId),document.body.appendChild(r)),document.body.appendChild(i),document.body.appendChild(n),document.body.appendChild(t);let s=null,l=new Map,a=Se(t,i,n,s,l,r,e);document.addEventListener("mousemove",a.handleMouseMove,!0),document.addEventListener("click",a.handleClick,!0),document.addEventListener("keydown",a.handleKeyDown,!0),window.__elementPickerHandlers=a,window.__elementPickerSelectedElements=l}function I(o={}){let e={...J,...o};console.log("[ElementPicker] Stopping element picker");let t=document.getElementById(e.overlayId);t&&t.remove();let i=document.getElementById(e.highlightId);i&&i.remove();let n=document.getElementById(e.tooltipId);n&&n.remove();let r=document.getElementById(e.controlPanelId);r&&r.remove();let s=window.__elementPickerSelectedElements;s&&(s.forEach((c,f)=>{f.classList.remove(e.selectedClass)}),delete window.__elementPickerSelectedElements);let l=document.getElementById("chrome-extension-picker-styles");l&&l.remove();let a=window.__elementPickerHandlers;a&&(document.removeEventListener("mousemove",a.handleMouseMove,!0),document.removeEventListener("click",a.handleClick,!0),document.removeEventListener("keydown",a.handleKeyDown,!0),delete window.__elementPickerHandlers)}function we(o){let e=document.createElement("div");return e.id=o,e.style.cssText=`
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    z-index: 2147483646;
    cursor: crosshair;
    background: transparent;
  `,e}function Ee(o){let e=document.createElement("div");return e.id=o,e.style.cssText=`
    position: fixed;
    border: 2px solid #4285f4;
    background: rgba(66, 133, 244, 0.1);
    pointer-events: none;
    transition: all 0.1s ease;
    display: none;
    z-index: 2147483647;
  `,e}function xe(o){let e=document.createElement("div");return e.id=o,e.style.cssText=`
    position: fixed;
    background: #333;
    color: white;
    padding: 4px 8px;
    border-radius: 4px;
    font-size: 12px;
    font-family: monospace;
    pointer-events: none;
    z-index: 2147483648;
    display: none;
    white-space: nowrap;
    box-shadow: 0 2px 4px rgba(0,0,0,0.2);
  `,e}function ke(o){let e=document.createElement("div");e.id=o,e.style.cssText=`
    position: fixed;
    bottom: 20px;
    right: 20px;
    background: #2a4050;
    color: white;
    padding: 16px;
    border-radius: 8px;
    font-family: sans-serif;
    font-size: 14px;
    z-index: 2147483649;
    box-shadow: 0 4px 8px rgba(0,0,0,0.3);
    min-width: 250px;
  `;let t=document.createElement("div");t.style.cssText=`
    font-weight: bold;
    margin-bottom: 8px;
    display: flex;
    align-items: center;
    gap: 8px;
  `,t.innerHTML='<span style="font-size: 16px;">\u{1F3AF}</span> Multi-Select Mode',e.appendChild(t);let i=document.createElement("div");i.id="picker-count",i.style.cssText=`
    margin-bottom: 12px;
    color: #4285F4;
  `,i.textContent="0 elements selected",e.appendChild(i);let n=document.createElement("div");n.style.cssText=`
    font-size: 12px;
    color: #ccc;
    margin-bottom: 12px;
    line-height: 1.4;
  `,n.innerHTML=`
    \u2022 Click to select/deselect elements<br>
    \u2022 Press <kbd style="background: #444; padding: 2px 4px; border-radius: 3px;">Enter</kbd> or click Done when finished<br>
    \u2022 Press <kbd style="background: #444; padding: 2px 4px; border-radius: 3px;">ESC</kbd> to cancel
  `,e.appendChild(n);let r=document.createElement("button");return r.id="picker-done",r.style.cssText=`
    background: #4285F4;
    color: white;
    border: none;
    padding: 8px 16px;
    border-radius: 4px;
    cursor: pointer;
    font-size: 14px;
    font-weight: 500;
    width: 100%;
    transition: background 0.2s;
  `,r.textContent="Done Selecting",r.onmouseover=()=>r.style.background="#1976D2",r.onmouseout=()=>r.style.background="#4285F4",e.appendChild(r),e}function Se(o,e,t,i,n,r,s){let l=h=>{o.style.pointerEvents="none";let g=document.elementFromPoint(h.clientX,h.clientY);if(o.style.pointerEvents="auto",g&&g!==i&&!g.id?.includes("chrome-extension-element-picker")){i=g;let m=g.getBoundingClientRect();e.style.display="block",e.style.left=`${m.left}px`,e.style.top=`${m.top}px`,e.style.width=`${m.width}px`,e.style.height=`${m.height}px`;let p=g.tagName.toLowerCase(),v=g.id?`#${g.id}`:"",u=g.className&&typeof g.className=="string"?`.${g.className.trim().split(/\s+/).filter(k=>k).join(".")}`:"";t.textContent=`${p}${v}${u}`,t.style.display="block";let b=Math.min(h.clientX+10,window.innerWidth-200),w=Math.min(h.clientY+10,window.innerHeight-30);t.style.left=`${b}px`,t.style.top=`${w}px`}},a=h=>{if(h.preventDefault(),h.stopPropagation(),h.target.id==="picker-done"){f();return}o.style.pointerEvents="none";let g=document.elementFromPoint(h.clientX,h.clientY);if(o.style.pointerEvents="auto",g&&!g.id?.includes("chrome-extension-element-picker")){let m=Ce(g),p=s.includeText?Me(g):void 0;if(s.multiSelect){if(n.has(g))n.delete(g),g.classList.remove(s.selectedClass),console.log("[ElementPicker] Element deselected:",m);else{let v={selector:m,html:p};n.set(g,v),g.classList.add(s.selectedClass),console.log("[ElementPicker] Element selected:",m)}c()}else console.log("[ElementPicker] Element picked:",m),s.includeText&&s.onElementPickedWithHtml?s.onElementPickedWithHtml({selector:m,html:p||""}):s.onElementPicked&&s.onElementPicked(m),I(s)}},c=()=>{let h=document.getElementById("picker-count");if(h){let g=n.size;h.textContent=`${g} element${g!==1?"s":""} selected`}},f=()=>{if(n.size>0){if(s.includeText&&s.onElementsPickedWithHtml){let h=Array.from(n.values()).map(g=>({selector:g.selector,html:g.html||""}));console.log("[ElementPicker] Multi-select finished with html:",h),s.onElementsPickedWithHtml(h)}else if(s.onElementsPicked){let h=Array.from(n.values()).map(g=>g.selector);console.log("[ElementPicker] Multi-select finished:",h),s.onElementsPicked(h)}}I(s)};return{handleMouseMove:l,handleClick:a,handleKeyDown:h=>{h.key==="Escape"?(s.onCancel&&s.onCancel(),I(s)):h.key==="Enter"&&s.multiSelect&&f()}}}function Me(o){let e=o.innerHTML||"";e=e.trim();let t=5e4;return e.length>t&&(e=e.substring(0,t)+"..."),e}function Ce(o){let e=o.getAttribute("n");if(e)return`[n="${e}"]`;if(o.id)return`#${o.id}`;let t=[],i=o;for(;i&&i.nodeType===Node.ELEMENT_NODE;){let n=i.nodeName.toLowerCase();if(i.className&&typeof i.className=="string"){let r=i.className.trim().split(/\s+/).filter(s=>s);r.length>0&&(n+="."+r.join("."))}if(i.parentNode){let r=Array.from(i.parentNode.children),s=r.indexOf(i)+1;r.length>1&&(n+=`:nth-child(${s})`)}if(t.unshift(n),i.id){t.unshift(`#${i.id}`);break}i=i.parentElement}return t.join(" > ")}var $=class{async querySelector(e,t){let i=document.querySelector(t);return i?i.outerHTML:null}async querySelectorAll(e,t){let i=document.querySelectorAll(t);return Array.from(i).map(n=>n.outerHTML)}async getInnerHTML(e,t){let i=document.querySelector(t);if(!i)throw new Error(`Element not found: ${t}`);return i.innerHTML}async getOuterHTML(e,t){let i=document.querySelector(t);if(!i)throw new Error(`Element not found: ${t}`);return i.outerHTML}async getTextContent(e,t){let i=document.querySelector(t);if(!i)throw new Error(`Element not found: ${t}`);return i.textContent??""}async getAttribute(e,t,i){let n=document.querySelector(t);return n?n.getAttribute(i):null}async click(e,t){let i=document.querySelector(t);if(!i)throw new Error(`Element not found: ${t}`);i.click()}async type(e,t,i){let n=document.querySelector(t);if(!n)throw new Error(`Element not found: ${t}`);n.focus(),n.value=i,n.dispatchEvent(new Event("input",{bubbles:!0})),n.dispatchEvent(new Event("change",{bubbles:!0}))}async focus(e,t){let i=document.querySelector(t);if(!i)throw new Error(`Element not found: ${t}`);i.focus()}async scrollTo(e,t){let i=document.querySelector(t);if(!i)throw new Error(`Element not found: ${t}`);i.scrollIntoView({behavior:"smooth",block:"center"})}async evaluate(e,t,...i){return typeof t=="string"?new Function("...args",`return (${t})(...args)`)(...i):t(...i)}async getReducedDom(e,t={}){let{maxDepth:i=10,includeAttributes:n=!0,excludeTags:r=["script","style","noscript","svg","path"],excludeAttributes:s=["style","class","onclick","onload"],maxTextLength:l=100,includeHidden:a=!1}=t;function c(y){if(!a){let h=window.getComputedStyle(y);if(h.display==="none"||h.visibility==="hidden")return!1}return!0}function f(y,h){if(h>i)return"";if(y.nodeType===Node.TEXT_NODE){let u=y.textContent?.trim()??"";return u?u.length>l?u.substring(0,l)+"...":u:""}if(y.nodeType!==Node.ELEMENT_NODE)return"";let g=y,m=g.tagName.toLowerCase();if(r.includes(m)||!c(g))return"";let p=`<${m}`;if(n){for(let u of g.attributes)if(!s.includes(u.name)){let b=u.value.length>50?u.value.substring(0,50)+"...":u.value;p+=` ${u.name}="${b}"`}}let v=Array.from(g.childNodes).map(u=>f(u,h+1)).filter(Boolean).join("");return v?p+=`>${v}</${m}>`:p+=" />",p}return f(document.body,0)}async getTitle(e){return document.title}async getUrl(e){return window.location.href}async waitForSelector(e,t,i=5e3){return new Promise(n=>{if(document.querySelector(t)){n(!0);return}let s=new MutationObserver(()=>{document.querySelector(t)&&(s.disconnect(),n(!0))});s.observe(document.body,{childList:!0,subtree:!0}),setTimeout(()=>{s.disconnect(),n(!1)},i)})}async getComputedStyles(e,t,i,n){if(i){let r=document.querySelectorAll(t),s=[];for(let l=0;l<r.length;l++){let a=r[l],c=window.getComputedStyle(a),f={};if(n&&n.length>0)n.forEach(y=>{f[y]=c.getPropertyValue(y)});else for(let y=0;y<c.length;y++){let h=c[y];f[h]=c.getPropertyValue(h)}s.push({selector:t,index:l,element:{tagName:a.tagName.toLowerCase(),id:a.id||void 0,className:a.className||void 0},computedStyles:f})}return s}else{let r=document.querySelector(t);if(!r)throw new Error("No element found matching selector: "+t);let s=window.getComputedStyle(r),l={};if(n&&n.length>0)n.forEach(c=>{l[c]=s.getPropertyValue(c)});else for(let c=0;c<s.length;c++){let f=s[c];l[f]=s.getPropertyValue(f)}let a=document.querySelectorAll(t).length;return{selector:t,element:{tagName:r.tagName.toLowerCase(),id:r.id||void 0,className:r.className||void 0},computedStyles:l,elementCount:a}}}async queryElementsFull(e,t,i){if(i){let n=document.querySelectorAll(t),r=[];for(let s=0;s<n.length;s++)r.push({selector:t,html:n[s].outerHTML,index:s});return r}else{let n=document.querySelector(t);if(!n)throw new Error("No element found matching selector: "+t);let r=document.querySelectorAll(t).length;return{selector:t,html:n.outerHTML,elementCount:r}}}async getInteractiveElements(e,t,i,n){let r=m=>{if(!n)return!0;let p=window.getComputedStyle(m);if(p.display==="none"||p.visibility==="hidden"||parseFloat(p.opacity)===0)return!1;let v=m.getBoundingClientRect();return!(v.width===0&&v.height===0||!m.offsetParent&&p.position!=="fixed"&&p.position!=="sticky")},s=m=>{if(m.id)return"#"+CSS.escape(m.id);let p=Array.from(m.classList).filter(k=>!k.match(/^(js-|is-|has-|ng-|v-|react-)/)).slice(0,2),v=m.tagName.toLowerCase();if(p.length>0&&(v+="."+p.map(k=>CSS.escape(k)).join(".")),document.querySelectorAll(v).length===1)return v;let u=[v],b=m.parentElement,w=0;for(;b&&b!==document.body&&w<3;){let k=b.tagName.toLowerCase();if(b.id){u.unshift("#"+CSS.escape(b.id));break}let H=Array.from(b.classList).filter(B=>!B.match(/^(js-|is-|has-|ng-|v-|react-)/)).slice(0,1);H.length>0&&(k+="."+CSS.escape(H[0])),u.unshift(k),b=b.parentElement,w++}return u.join(" > ")},l=(m,p=100)=>{let v=(m.textContent||"").trim().replace(/\s+/g," ");return v.length>p?v.substring(0,p)+"...":v},a=[],c=0,f='button, [role="button"], input[type="button"], input[type="submit"], input[type="reset"]',y="a[href]",h='input:not([type="hidden"]):not([type="button"]):not([type="submit"]):not([type="reset"]), textarea, select',g=(m,p)=>{document.querySelectorAll(m).forEach(u=>{if(!r(u)||(c++,a.length>=i))return;let b={type:p,selector:s(u)};if(p==="button"){b.text=l(u),b.disabled=u.disabled||u.getAttribute("aria-disabled")==="true";let w=u.getAttribute("aria-label");w&&(b.ariaLabel=w)}else if(p==="link"){b.text=l(u),b.href=u.getAttribute("href")||void 0;let w=u.getAttribute("aria-label");w&&(b.ariaLabel=w)}else if(p==="input"){let w=u;b.inputType=w.type||w.tagName.toLowerCase(),w.name&&(b.name=w.name),w.placeholder&&(b.placeholder=w.placeholder),b.disabled=w.disabled;let k=u.getAttribute("aria-label");k&&(b.ariaLabel=k)}a.push(b)})};return(t==="all"||t==="button")&&g(f,"button"),(t==="all"||t==="link")&&g(y,"link"),(t==="all"||t==="input")&&g(h,"input"),{elements:a,meta:{total:c,returned:a.length,truncated:c>a.length,limit:i}}}async getForms(e,t,i){let n=a=>{if(a.id)return"#"+CSS.escape(a.id);let c=Array.from(a.classList).filter(m=>!m.match(/^(js-|is-|has-|ng-|v-|react-)/)).slice(0,2),f=a.tagName.toLowerCase();if(c.length>0&&(f+="."+c.map(m=>CSS.escape(m)).join(".")),document.querySelectorAll(f).length===1)return f;let y=[f],h=a.parentElement,g=0;for(;h&&h!==document.body&&g<3;){let m=h.tagName.toLowerCase();if(h.id){y.unshift("#"+CSS.escape(h.id));break}let p=Array.from(h.classList).filter(v=>!v.match(/^(js-|is-|has-|ng-|v-|react-)/)).slice(0,1);p.length>0&&(m+="."+CSS.escape(p[0])),y.unshift(m),h=h.parentElement,g++}return y.join(" > ")},r=document.querySelectorAll("form"),s=r.length,l=[];return r.forEach(a=>{if(l.length>=t)return;let c={selector:n(a),fields:[]};a.id&&(c.id=a.id),a.name&&(c.name=a.name),a.action&&(c.action=a.action),a.method&&(c.method=a.method.toUpperCase()),a.querySelectorAll('input:not([type="hidden"]), textarea, select, button[type="submit"], input[type="submit"]').forEach(h=>{if(c.fields.length>=i)return;let g={tag:h.tagName.toLowerCase(),selector:n(h)},m=h;m.type&&(g.type=m.type),m.name&&(g.name=m.name),m.id&&(g.id=m.id),m.placeholder&&(g.placeholder=m.placeholder),m.required&&(g.required=!0),m.disabled&&(g.disabled=!0);let p=h.getAttribute("aria-label");if(p&&(g.ariaLabel=p),h.tagName.toLowerCase()==="select"){let v=[];h.querySelectorAll("option").forEach((u,b)=>{b<10&&v.push({value:u.value,text:u.textContent?.trim()||""})}),v.length>0&&(g.options=v)}c.fields.push(g)}),l.push(c)}),{forms:l,meta:{total:s,returned:l.length,truncated:s>l.length,limit:t}}}async executeCode(e,t){let i=[],n={log:console.log,warn:console.warn,error:console.error,info:console.info,debug:console.debug};console.log=(...r)=>{i.push(`[log] ${r.map(s=>String(s)).join(" ")}`),n.log(...r)},console.warn=(...r)=>{i.push(`[warn] ${r.map(s=>String(s)).join(" ")}`),n.warn(...r)},console.error=(...r)=>{i.push(`[error] ${r.map(s=>String(s)).join(" ")}`),n.error(...r)},console.info=(...r)=>{i.push(`[info] ${r.map(s=>String(s)).join(" ")}`),n.info(...r)},console.debug=(...r)=>{i.push(`[debug] ${r.map(s=>String(s)).join(" ")}`),n.debug(...r)};try{let s=new Function(t)();return{returnValue:s instanceof Promise?await s:s,logs:i,error:void 0}}catch(r){return{returnValue:void 0,logs:i,error:r instanceof Error?r.message:String(r)}}finally{console.log=n.log,console.warn=n.warn,console.error=n.error,console.info=n.info,console.debug=n.debug}}};function Ie(o){let e=o.id.replace(/'/g,"\\'").replace(/\\/g,"\\\\"),t=JSON.stringify(o.description||o.name),i=JSON.stringify(o.parameters||{type:"object",properties:{}}),n=o.implementation;return`
(function() {
  'use strict';

  // Initialize navigator.modelContext with Web MCP standard API
  if (!navigator.modelContext) {
    navigator.modelContext = {
      tools: [],
      // Web MCP standard: list() returns an iterable of tools
      list: function() { return this.tools; },
      // Web MCP standard: executeTool dispatches to tool's execute method
      executeTool: async function(name, args) {
        var tool = this.tools.find(function(t) { return t.name === name; });
        if (!tool) {
          return {
            content: [{ type: 'text', text: 'Tool not found: ' + name }],
            isError: true
          };
        }
        try {
          var result = await tool.execute(args);
          // If result is already in CallToolResult format, return as-is
          if (result && typeof result === 'object' && Array.isArray(result.content)) {
            return result;
          }
          // Wrap primitive/object results in CallToolResult format
          return {
            content: [{ type: 'text', text: typeof result === 'string' ? result : JSON.stringify(result) }],
            isError: false
          };
        } catch (error) {
          return {
            content: [{ type: 'text', text: 'Tool execution error: ' + (error.message || String(error)) }],
            isError: true
          };
        }
      }
    };
  }
  if (!navigator.modelContext.tools) {
    navigator.modelContext.tools = [];
  }
  // Ensure list() function exists (for pages that already have partial modelContext)
  if (!navigator.modelContext.list) {
    navigator.modelContext.list = function() { return this.tools; };
  }
  // Ensure executeTool() function exists (required by CallWebToolHandler)
  if (!navigator.modelContext.executeTool) {
    navigator.modelContext.executeTool = async function(name, args) {
      var tool = this.tools.find(function(t) { return t.name === name; });
      if (!tool) {
        return {
          content: [{ type: 'text', text: 'Tool not found: ' + name }],
          isError: true
        };
      }
      try {
        var result = await tool.execute(args);
        if (result && typeof result === 'object' && Array.isArray(result.content)) {
          return result;
        }
        return {
          content: [{ type: 'text', text: typeof result === 'string' ? result : JSON.stringify(result) }],
          isError: false
        };
      } catch (error) {
        return {
          content: [{ type: 'text', text: 'Tool execution error: ' + (error.message || String(error)) }],
          isError: true
        };
      }
    };
  }

  // Check if tool already registered
  if (navigator.modelContext.tools.some(t => t.name === '${e}')) {
    return;
  }

  // Register the tool
  navigator.modelContext.tools.push({
    name: '${e}',
    description: ${t},
    // Web MCP uses inputSchema, not parameters
    inputSchema: ${i},
    // Metadata for deduplication - allows discovery to identify this as a deployed tool
    _deployedId: '${e}',
    _source: 'deployed',
    execute: async function(params) {
      try {
        ${n}
      } catch (error) {
        console.error('[DeployedTool:${e}] Execution error:', error);
        throw error;
      }
    }
  });

  console.log('[DeployedTool] Registered: ${e}');
})();
`}function Q(o){let e={injected:[],failed:[]};for(let t of o)try{let i=Ie(t),n=document.createElement("script");n.textContent=i,(document.head||document.documentElement).appendChild(n),Te(t.id)?e.injected.push(t.id):e.failed.push({id:t.id,name:t.name,reason:"Script failed to register - likely contains TypeScript syntax or JavaScript errors. Check browser console."})}catch(i){let n=i instanceof Error?i.message:String(i);e.failed.push({id:t.id,name:t.name,reason:n})}return e}function Te(o){if(typeof navigator>"u"||!navigator.modelContext)return!1;let e=navigator.modelContext;return!e.tools||!Array.isArray(e.tools)?!1:e.tools.some(t=>t.name===o)}var Re="https://llm-proxy.ripul.io",S=null,z=class o{constructor(e={}){d(this,"config");d(this,"connectedFrames",new Set);d(this,"isInitialized",!1);d(this,"domAdapter",new $);d(this,"discoveredToolIds",new Set);d(this,"toolDiscoveryPromise",null);d(this,"debugMessageListener",null);d(this,"activeElementPickerRequest",null);d(this,"handleMessage",async e=>{if(this.config.debug&&e.data?.type?.startsWith?.("agent-framework:")&&console.log("[FrameBridgeDebug] Host: RAW message:",e.origin,e.data?.type),!this.isAllowedOrigin(e.origin)||!O(e.data))return;let t=e.data;try{switch(t.type){case`${E}handshake`:await this.handleHandshake(e,t);break;case`${E}host:info`:await this.handleHostInfo(e,t);break;case`${E}mcp:discover`:await this.handleMCPDiscover(e,t);break;case`${E}mcp:invoke`:await this.handleMCPInvoke(e,t);break;case`${E}dom:request`:await this.handleDOMRequest(e,t);break;case`${E}tools:inject`:await this.handleToolsInject(e,t);break;case`${E}elementPicker:start`:await this.handleElementPickerStart(e,t);break;case`${E}elementPicker:stop`:await this.handleElementPickerStop(e,t);break;case`${E}ping`:this.sendToFrame(e.source,e.origin,x("pong",{}));break}}catch(i){console.error("HostMCPProvider: Error handling message:",i)}});this.config={allowedOrigins:e.allowedOrigins??["*"],enableMCP:e.enableMCP??!0,enableDOM:e.enableDOM??!1,enableElementPicker:e.enableElementPicker??!0,toolProvider:e.toolProvider??this.createDefaultToolProvider(),debug:e.debug??!1,enableToolDiscovery:e.enableToolDiscovery??!1,toolDiscoveryUrl:e.toolDiscoveryUrl??Re,enableAutoRun:e.enableAutoRun??!1,autoRunTiming:e.autoRunTiming??"immediate",onAutoRunComplete:e.onAutoRunComplete??void 0}}static getInstance(e){return window.__agentFrameworkHostBridge?(e&&console.log("[FrameBridge:Host] Bridge already exists (from window global), ignoring new config"),S=window.__agentFrameworkHostBridge,window.__agentFrameworkHostBridge):S?(e&&console.log("[FrameBridge:Host] Bridge already exists, ignoring new config"),S):(S=new o(e),window.__agentFrameworkHostBridge=S,console.log("[FrameBridge:Host] Created singleton HostMCPBridge"),S)}init(){if(this.isInitialized){this.log("Bridge already initialized");return}window.addEventListener("message",this.handleMessage),this.isInitialized=!0,this.printStartupBanner(),this.log("Host bridge initialized",{config:this.config}),this.config.debug&&(this.debugMessageListener=e=>{typeof e.data=="string"||e.data?.source?.includes?.("devtools")||console.log("[FrameBridgeDebug] Host: ALL messages:",{origin:e.origin,dataType:typeof e.data,data:e.data,hasType:"type"in(e.data||{}),type:e.data?.type})},window.addEventListener("message",this.debugMessageListener)),this.config.debug&&this.config.enableToolDiscovery&&this.log("Tool discovery enabled - will request from iframe after handshake")}async handleToolsInject(e,t){if(!t.success){this.log("Tool discovery from iframe failed",{error:t.error});return}let i=t.tools||[];if(i.length===0)return;let n=i.filter(l=>!this.discoveredToolIds.has(l.id));if(n.length===0){this.log("All deployed tools already injected");return}let r=n.map(l=>({id:l.id,name:l.name,description:l.description,parameters:l.parameters,implementation:l.implementation,filters:[],version:1,enabled:!0,createdAt:new Date().toISOString(),updatedAt:new Date().toISOString(),createdBy:"iframe-discovery",teamId:"default",visibility:"public"})),s=Q(r);for(let l of s.injected)this.discoveredToolIds.add(l);if(s.injected.length>0&&console.log(`[FrameBridge:Host] \u2713 Injected ${s.injected.length} deployed tools into navigator.modelContext`),s.failed.length>0){let l=s.failed.map(a=>a.name).join(", ");console.warn(`[FrameBridge:Host] \u26A0\uFE0F ${s.failed.length} tool(s) failed to inject: ${l}. This usually means the tool implementation contains TypeScript syntax or JavaScript errors.`)}if(e.source&&this.sendToFrame(e.source,e.origin,x("tools:inject-result",{requestId:t.requestId,injected:s.injected,failed:s.failed})),this.config.enableAutoRun){let l=n.filter(a=>a.autoRun?.enabled&&s.injected.includes(a.id));l.length>0&&(this.log("Auto-run enabled, executing tools",{count:l.length,tools:l.map(a=>a.name)}),await this.executeAutoRunTools(l))}}async executeAutoRunTools(e){let t=[];for(let i of e){let n=this.config.autoRunTiming??i.autoRun?.timing??"immediate",r=i.autoRun?.defaultArgs??{};this.log("Scheduling auto-run",{tool:i.name,timing:n,args:r});let s=async()=>{let l=performance.now();try{if(typeof navigator>"u"||!navigator.modelContext)throw new Error("navigator.modelContext not available");let a=await navigator.modelContext.executeTool(i.name,r),c=performance.now()-l;this.log("Auto-run completed",{tool:i.name,duration:c,success:!0}),t.push({toolName:i.name,toolId:i.id,success:!0,result:a,duration:c})}catch(a){let c=performance.now()-l,f=a instanceof Error?a.message:String(a);console.error(`[AutoRun] Tool ${i.name} failed:`,a),this.log("Auto-run failed",{tool:i.name,duration:c,error:f}),t.push({toolName:i.name,toolId:i.id,success:!1,error:f,duration:c})}t.length===e.length&&this.config.onAutoRunComplete&&(this.log("All auto-run tools completed",{resultCount:t.length}),this.config.onAutoRunComplete(t))};switch(n){case"idle":"requestIdleCallback"in window?window.requestIdleCallback(()=>s(),{timeout:5e3}):setTimeout(()=>s(),100);break;case"domReady":document.readyState==="loading"?document.addEventListener("DOMContentLoaded",()=>s(),{once:!0}):await s();break;case"immediate":default:await s();break}}}destroy(){window.removeEventListener("message",this.handleMessage),this.debugMessageListener&&(window.removeEventListener("message",this.debugMessageListener),this.debugMessageListener=null),this.connectedFrames.clear(),this.isInitialized=!1,S===this&&(S=null),window.__agentFrameworkHostBridge===this&&delete window.__agentFrameworkHostBridge,this.log("Host bridge destroyed")}getCapabilities(){return{mcp:this.config.enableMCP,dom:this.config.enableDOM,storage:!1,elementPicker:this.config.enableElementPicker}}async handleHandshake(e,t){e.source&&this.connectedFrames.add(e.source);let i=this.getCapabilities();console.log("[DEBUG_ELEMENTPICKER] HostMCPProvider: getCapabilities() returned:",JSON.stringify(i)),console.log("[DEBUG_ELEMENTPICKER] HostMCPProvider: elementPicker value:",i.elementPicker,"type:",typeof i.elementPicker),console.log("[DEBUG_ELEMENTPICKER] HostMCPProvider: config.enableElementPicker:",this.config.enableElementPicker);let n=x("handshake:ack",{capabilities:i,hostOrigin:window.location.origin});if(console.log("[DEBUG_ELEMENTPICKER] HostMCPProvider: Full ack message:",JSON.stringify(n)),this.sendToFrame(e.source,e.origin,n),this.config.enableToolDiscovery&&e.source){let r=`discover-${Date.now()}`;this.log("Requesting deployed tools from iframe"),this.sendToFrame(e.source,e.origin,x("tools:discover-request",{requestId:r,hostUrl:window.location.href,hostDomain:window.location.hostname}))}}async handleHostInfo(e,t){this.sendToFrame(e.source,e.origin,x("host:info:response",{requestId:t.requestId,url:window.location.href,title:document.title,origin:window.location.origin}))}async handleMCPDiscover(e,t){if(!this.config.enableMCP){this.log("MCP disabled, sending empty tools to iframe"),this.sendToFrame(e.source,e.origin,x("mcp:tools",{tools:[],requestId:t.requestId}));return}try{let i=this.config.toolProvider.listTools();this.printToolDiscoverySummary(i);let n=x("mcp:tools",{tools:i,requestId:t.requestId});this.sendToFrame(e.source,e.origin,n)}catch(i){console.error("[AgentFramework] Tool discovery failed:",i),this.log("listTools() failed",{error:i}),this.sendToFrame(e.source,e.origin,x("mcp:tools",{tools:[],requestId:t.requestId}))}}printToolDiscoverySummary(e){let t=typeof navigator<"u"&&!!navigator.modelContext,i=["\u{1F916} Agent Framework - Native MCP Tools","\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500"];e.length===0?(i.push("  Status: No tools discovered"),i.push(`  navigator.modelContext: ${t?"\u2713 present":"\u2717 missing"}`)):(i.push(`  Status: ${e.length} tool${e.length===1?"":"s"} available`),i.push(""),e.forEach((n,r)=>{let s=n.description?n.description.substring(0,50)+(n.description.length>50?"...":""):"(no description)";i.push(`  ${r+1}. ${n.name} - ${s}`)})),i.push("\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500"),console.log(i.join(`
`))}printStartupBanner(){let e=typeof navigator<"u"&&!!navigator.modelContext,t=0;if(e)try{for(let r of navigator.modelContext.list())t++}catch{}let i=this.config.enableMCP?"\u2713 enabled":"\u2717 disabled",n=e?`${t} available`:"no modelContext";console.log(`\u{1F916} Agent Framework - Host Bridge Ready
   MCP: ${i} | Native tools: ${n}`)}async handleMCPInvoke(e,t){if(!this.config.enableMCP){this.sendToFrame(e.source,e.origin,x("mcp:error",{requestId:t.requestId,error:"MCP is not enabled on this host",code:"MCP_DISABLED"}));return}try{this.log("Invoking tool",{tool:t.toolName,args:t.args});let i=await this.config.toolProvider.executeTool(t.toolName,t.args);this.sendToFrame(e.source,e.origin,x("mcp:result",{requestId:t.requestId,result:i}))}catch(i){this.sendToFrame(e.source,e.origin,x("mcp:error",{requestId:t.requestId,error:i instanceof Error?i.message:String(i),code:"EXECUTION_ERROR"}))}}async handleDOMRequest(e,t){if(!this.config.enableDOM){this.sendToFrame(e.source,e.origin,x("dom:response",{requestId:t.requestId,success:!1,error:"DOM access not enabled on this host"}));return}try{let{method:i,args:n}=t,r=this.domAdapter[i];if(typeof r!="function")throw new Error(`Unknown DOM method: ${i}`);let s=await r.call(this.domAdapter,0,...n.slice(1));this.sendToFrame(e.source,e.origin,x("dom:response",{requestId:t.requestId,success:!0,data:s}))}catch(i){this.sendToFrame(e.source,e.origin,x("dom:response",{requestId:t.requestId,success:!1,error:i instanceof Error?i.message:String(i)}))}}async handleElementPickerStart(e,t){if(console.log("[DEBUG_ELEMENTPICKER] HostMCPProvider: Received elementPicker:start request",{requestId:t.requestId,enableElementPicker:this.config.enableElementPicker}),!this.config.enableElementPicker){console.log("[DEBUG_ELEMENTPICKER] HostMCPProvider: Element picker not enabled, ignoring"),this.log("Element picker not enabled, ignoring request");return}this.activeElementPickerRequest&&(this.log("Stopping existing element picker before starting new one"),I()),this.activeElementPickerRequest={requestId:t.requestId,source:e.source,origin:e.origin},console.log("[DEBUG_ELEMENTPICKER] HostMCPProvider: Starting element picker on HOST page DOM"),this.log("Starting element picker on host page",{requestId:t.requestId,options:t.options});let i=t.options??{};Z({multiSelect:i.multiSelect,includeText:i.includeText,onElementPickedWithHtml:n=>{console.log("[DEBUG_ELEMENTPICKER] HostMCPProvider: Element picked from host",{selector:n.selector}),this.log("Element picked",{selector:n.selector}),this.activeElementPickerRequest&&(this.sendToFrame(this.activeElementPickerRequest.source,this.activeElementPickerRequest.origin,x("elementPicker:result",{requestId:this.activeElementPickerRequest.requestId,result:{selector:n.selector,html:n.html}})),this.activeElementPickerRequest=null)},onElementsPickedWithHtml:n=>{this.log("Multiple elements picked",{count:n.length}),this.activeElementPickerRequest&&(this.sendToFrame(this.activeElementPickerRequest.source,this.activeElementPickerRequest.origin,x("elementPicker:result",{requestId:this.activeElementPickerRequest.requestId,result:{selectors:n.map(r=>r.selector),htmls:n.map(r=>r.html)}})),this.activeElementPickerRequest=null)},onCancel:()=>{this.log("Element picker cancelled"),this.activeElementPickerRequest&&(this.sendToFrame(this.activeElementPickerRequest.source,this.activeElementPickerRequest.origin,x("elementPicker:cancelled",{requestId:this.activeElementPickerRequest.requestId})),this.activeElementPickerRequest=null)}})}async handleElementPickerStop(e,t){this.config.enableElementPicker&&(this.log("Stopping element picker",{requestId:t.requestId}),I(),this.activeElementPickerRequest=null)}isAllowedOrigin(e){return this.config.allowedOrigins.includes("*")?!0:this.config.allowedOrigins.includes(e)}sendToFrame(e,t,i){this.log("Sending message",{type:i.type,origin:t}),e.postMessage(i,t)}createDefaultToolProvider(){return{listTools:()=>{if(typeof navigator<"u"&&navigator.modelContext){let e=[];for(let t of navigator.modelContext.list())e.push({name:t.name,description:t.description,inputSchema:t.inputSchema});return e}return[]},executeTool:async(e,t)=>{if(typeof navigator<"u"&&navigator.modelContext)return await navigator.modelContext.executeTool(e,t);throw new Error(`Tool ${e} not found - no modelContext available`)}}}log(e,t){this.config.debug&&console.log(`[FrameBridgeDebug] Host: ${e}`,t??"")}};function ee(o){let e=z.getInstance(o);return e.init(),e}if(typeof document<"u"){let o=document.currentScript,e=o?.getAttribute("src")??"",t=e.includes("bridge.js")&&!e.includes("embed.js");if(o&&t){let i={},n=o.getAttribute("data-allowed-origins");n&&(i.allowedOrigins=n.split(",").map(s=>s.trim())),o.hasAttribute("data-debug")&&(i.debug=!0),o.hasAttribute("data-disable-mcp")&&(i.enableMCP=!1),o.hasAttribute("data-enable-dom")&&(i.enableDOM=!0),o.hasAttribute("data-enable-tool-discovery")&&(i.enableToolDiscovery=!0);let r=o.getAttribute("data-tool-discovery-url");r&&(i.toolDiscoveryUrl=r),document.readyState==="loading"?document.addEventListener("DOMContentLoaded",()=>ee(i)):ee(i)}}var te=`
  .agent-framework-container {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  }

  /* ========== Floating Mode ========== */
  .agent-framework-floating {
    position: fixed;
    z-index: var(--af-z-index, 999999);
    transition: opacity 0.2s, transform 0.2s;
    /* Allow touch/click events to pass through to underlying page */
    pointer-events: none;
  }

  .agent-framework-floating.bottom-right {
    bottom: 20px;
    right: 20px;
  }

  .agent-framework-floating.bottom-left {
    bottom: 20px;
    left: 20px;
  }

  .agent-framework-floating.top-right {
    top: 20px;
    right: 20px;
  }

  .agent-framework-floating.top-left {
    top: 20px;
    left: 20px;
  }

  .agent-framework-floating.center {
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
  }

  /* Custom position (via initialX/initialY or drag) */
  .agent-framework-floating.custom-position {
    bottom: auto;
    right: auto;
    top: auto;
    left: auto;
  }

  .agent-framework-iframe-wrapper {
    background: white;
    border-radius: 12px;
    box-shadow: 0 5px 40px rgba(0, 0, 0, 0.16);
    overflow: hidden;
    opacity: 0;
    transform: scale(0.95) translateY(10px);
    transition: opacity 0.2s, transform 0.2s;
    pointer-events: none;
    position: relative;
    min-width: 300px;
    min-height: 400px;
  }

  /* Resize handle */
  .agent-framework-resize-handle {
    position: absolute;
    bottom: 0;
    right: 0;
    width: 16px;
    height: 16px;
    cursor: nwse-resize;
    z-index: 10;
  }

  .agent-framework-resize-handle::before {
    content: '';
    position: absolute;
    bottom: 4px;
    right: 4px;
    width: 8px;
    height: 8px;
    border-right: 2px solid rgba(0, 0, 0, 0.3);
    border-bottom: 2px solid rgba(0, 0, 0, 0.3);
  }

  .agent-framework-iframe-wrapper.theme-dark .agent-framework-resize-handle::before {
    border-right-color: rgba(255, 255, 255, 0.3);
    border-bottom-color: rgba(255, 255, 255, 0.3);
  }

  .agent-framework-resize-handle:hover::before {
    border-right-color: rgba(80, 70, 229, 0.8);
    border-bottom-color: rgba(80, 70, 229, 0.8);
  }

  .agent-framework-iframe-wrapper.visible {
    opacity: 1;
    transform: scale(1) translateY(0);
    pointer-events: auto;
  }

  .agent-framework-iframe-wrapper.maximized {
    position: fixed !important;
    top: 0 !important;
    left: 0 !important;
    width: 100vw !important;
    height: 100vh !important;
    border-radius: 0;
    margin-bottom: 0 !important;
    max-width: none;
    max-height: none;
  }

  .agent-framework-iframe-wrapper.maximized .agent-framework-resize-handle {
    display: none;
  }

  .agent-framework-iframe {
    border: none;
    width: 100%;
    height: 100%;
  }

  .agent-framework-launcher {
    width: 60px;
    height: 60px;
    border-radius: 50%;
    background: #5046e5;
    border: none;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 4px 12px rgba(80, 70, 229, 0.4);
    transition: transform 0.2s, box-shadow 0.2s, background 0.3s ease, color 0.3s ease;
    position: absolute;
    bottom: 0;
    right: 0;
    color: white;
    /* Re-enable pointer events (parent has pointer-events: none) */
    pointer-events: auto;
  }

  .agent-framework-launcher.draggable {
    cursor: grab;
  }

  .agent-framework-launcher.draggable:active {
    cursor: grabbing;
  }

  .agent-framework-launcher.dragging {
    transition: none;
    cursor: grabbing;
  }

  .agent-framework-launcher:hover {
    transform: scale(1.05);
    box-shadow: 0 6px 16px rgba(80, 70, 229, 0.5);
  }

  .agent-framework-launcher svg {
    width: 28px;
    height: 28px;
    fill: currentColor;
    transition: fill 0.3s ease;
  }

  .agent-framework-launcher.open svg.chat-icon {
    display: none;
  }

  .agent-framework-launcher:not(.open) svg.close-icon {
    display: none;
  }

  /* Active/Waiting states - larger launcher to indicate activity */
  .agent-framework-launcher.status-active,
  .agent-framework-launcher.status-waiting {
    width: 72px;
    height: 72px;
    box-shadow: 0 4px 16px rgba(80, 70, 229, 0.5);
  }

  .agent-framework-launcher.status-active svg,
  .agent-framework-launcher.status-waiting svg {
    width: 32px;
    height: 32px;
  }

  /* Waiting state - subtle pulse animation to draw attention */
  .agent-framework-launcher.status-waiting {
    animation: launcher-pulse 2s ease-in-out infinite;
  }

  @keyframes launcher-pulse {
    0%, 100% {
      box-shadow: 0 4px 16px rgba(80, 70, 229, 0.5);
    }
    50% {
      box-shadow: 0 4px 24px rgba(80, 70, 229, 0.7);
    }
  }

  /* Active state - subtle spinning indicator */
  .agent-framework-launcher.status-active::after {
    content: '';
    position: absolute;
    top: -3px;
    left: -3px;
    right: -3px;
    bottom: -3px;
    border-radius: 50%;
    border: 2px solid transparent;
    border-top-color: rgba(255, 255, 255, 0.6);
    animation: launcher-spin 1s linear infinite;
    pointer-events: none;
  }

  @keyframes launcher-spin {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
  }

  /* Drag handle for iframe wrapper */
  .agent-framework-drag-handle {
    height: 32px;
    background: linear-gradient(135deg, #5046e5 0%, #6366f1 100%);
    cursor: grab;
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 12px;
    user-select: none;
    transition: background 0.3s ease, color 0.3s ease;
  }

  .agent-framework-drag-handle:active {
    cursor: grabbing;
  }

  .agent-framework-drag-handle-title {
    color: white;
    font-size: 13px;
    font-weight: 500;
    transition: color 0.3s ease;
  }

  .agent-framework-drag-handle-buttons {
    display: flex;
    gap: 8px;
  }

  .agent-framework-minimize-btn,
  .agent-framework-maximize-btn,
  .agent-framework-dock-btn,
  .agent-framework-close-btn {
    background: rgba(255, 255, 255, 0.2);
    border: none;
    border-radius: 4px;
    width: 24px;
    height: 24px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: background 0.2s, color 0.3s ease;
    color: white;
  }

  .agent-framework-minimize-btn:hover,
  .agent-framework-maximize-btn:hover,
  .agent-framework-dock-btn:hover,
  .agent-framework-close-btn:hover {
    background: rgba(255, 255, 255, 0.3);
  }

  .agent-framework-minimize-btn svg,
  .agent-framework-maximize-btn svg,
  .agent-framework-dock-btn svg,
  .agent-framework-close-btn svg {
    width: 14px;
    height: 14px;
    fill: currentColor;
    transition: fill 0.3s ease;
  }

  /* ========== Side Panel Mode ========== */
  .agent-framework-side-panel {
    position: fixed;
    top: 0;
    height: 100vh;
    z-index: var(--af-z-index, 999999);
    background: white;
    box-shadow: -5px 0 40px rgba(0, 0, 0, 0.1);
    transform: translateX(100%);
    transition: transform 0.3s ease-in-out;
    display: flex;
    flex-direction: column;
  }

  /* Side panel header */
  .agent-framework-side-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 8px 12px;
    background: #5046e5;
    color: white;
    flex-shrink: 0;
    height: 32px;
    box-sizing: border-box;
    transition: background 0.3s ease, color 0.3s ease;
  }

  .agent-framework-side-header-title {
    font-size: 13px;
    font-weight: 500;
    transition: color 0.3s ease;
  }

  .agent-framework-side-header-buttons {
    display: flex;
    gap: 8px;
  }

  .agent-framework-float-btn {
    background: rgba(255, 255, 255, 0.2);
    border: none;
    border-radius: 4px;
    width: 24px;
    height: 24px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: background 0.2s, color 0.3s ease;
    color: white;
  }

  .agent-framework-float-btn:hover {
    background: rgba(255, 255, 255, 0.3);
  }

  .agent-framework-float-btn svg {
    width: 14px;
    height: 14px;
    fill: currentColor;
    transition: fill 0.3s ease;
  }

  .agent-framework-side-header .agent-framework-close-btn {
    background: rgba(255, 255, 255, 0.2);
    color: white;
  }

  .agent-framework-side-header .agent-framework-close-btn:hover {
    background: rgba(255, 255, 255, 0.3);
  }

  .agent-framework-side-header .agent-framework-close-btn svg {
    fill: currentColor;
  }

  /* Side panel iframe container */
  .agent-framework-side-iframe-container {
    flex: 1;
    overflow: hidden;
  }

  .agent-framework-side-iframe-container .agent-framework-iframe {
    width: 100%;
    height: 100%;
  }

  .agent-framework-side-panel.left {
    left: 0;
    right: auto;
    transform: translateX(-100%);
    box-shadow: 5px 0 40px rgba(0, 0, 0, 0.1);
  }

  .agent-framework-side-panel.right {
    right: 0;
    left: auto;
  }

  .agent-framework-side-panel.visible {
    transform: translateX(0);
  }

  .agent-framework-side-panel .agent-framework-iframe {
    width: 100%;
    height: 100%;
  }

  /* Push page content when side panel is open */
  body.agent-framework-side-open-right {
    margin-right: var(--af-side-width, 400px);
    transition: margin-right 0.3s ease-in-out;
  }

  body.agent-framework-side-open-left {
    margin-left: var(--af-side-width, 400px);
    transition: margin-left 0.3s ease-in-out;
  }

  /* Side panel toggle button */
  .agent-framework-side-toggle {
    position: fixed;
    top: 50%;
    transform: translateY(-50%);
    width: 24px;
    height: 60px;
    background: #5046e5;
    border: none;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 2px 8px rgba(80, 70, 229, 0.4);
    z-index: var(--af-z-index, 999999);
    transition: transform 0.2s;
  }

  .agent-framework-side-toggle.right {
    right: 0;
    border-radius: 8px 0 0 8px;
  }

  .agent-framework-side-toggle.left {
    left: 0;
    border-radius: 0 8px 8px 0;
  }

  .agent-framework-side-toggle.visible.right {
    right: var(--af-side-width, 400px);
  }

  .agent-framework-side-toggle.visible.left {
    left: var(--af-side-width, 400px);
  }

  .agent-framework-side-toggle svg {
    width: 16px;
    height: 16px;
    fill: white;
    transition: transform 0.3s;
  }

  .agent-framework-side-toggle.visible svg {
    transform: rotate(180deg);
  }

  /* ========== Side Panel Splitter ========== */
  .agent-framework-side-splitter {
    position: absolute;
    top: 0;
    bottom: 0;
    width: 6px;
    cursor: col-resize;
    background: transparent;
    z-index: 10;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: background-color 0.15s ease;
  }

  /* Position splitter on inner edge based on panel side */
  .agent-framework-side-panel.right .agent-framework-side-splitter {
    left: 0;
  }

  .agent-framework-side-panel.left .agent-framework-side-splitter {
    right: 0;
  }

  /* Splitter grip indicator */
  .agent-framework-side-splitter::before {
    content: '';
    width: 4px;
    height: 40px;
    background: rgba(0, 0, 0, 0.15);
    border-radius: 2px;
    transition: background-color 0.15s ease, height 0.15s ease;
  }

  .agent-framework-side-splitter:hover {
    background: rgba(80, 70, 229, 0.1);
  }

  .agent-framework-side-splitter:hover::before {
    background: rgba(80, 70, 229, 0.5);
    height: 60px;
  }

  .agent-framework-side-splitter.dragging {
    background: rgba(80, 70, 229, 0.15);
  }

  .agent-framework-side-splitter.dragging::before {
    background: #5046e5;
    height: 80px;
  }

  /* Wider invisible hit area for easier grabbing */
  .agent-framework-side-splitter::after {
    content: '';
    position: absolute;
    top: 0;
    bottom: 0;
    left: -6px;
    right: -6px;
    z-index: -1;
  }

  /* Disable pointer events during resize */
  .agent-framework-side-panel.resizing .agent-framework-iframe {
    pointer-events: none;
  }

  /* Dark theme splitter */
  .agent-framework-side-panel.theme-dark .agent-framework-side-splitter::before {
    background: rgba(255, 255, 255, 0.15);
  }

  .agent-framework-side-panel.theme-dark .agent-framework-side-splitter:hover::before {
    background: rgba(80, 70, 229, 0.7);
  }

  @media (prefers-color-scheme: dark) {
    .agent-framework-side-panel.theme-system .agent-framework-side-splitter::before {
      background: rgba(255, 255, 255, 0.15);
    }

    .agent-framework-side-panel.theme-system .agent-framework-side-splitter:hover::before {
      background: rgba(80, 70, 229, 0.7);
    }
  }

  @media (prefers-color-scheme: dark) {
    .agent-framework-iframe-wrapper.theme-system,
    .agent-framework-side-panel.theme-system {
      background: #1a1a1a;
    }
  }

  .agent-framework-iframe-wrapper.theme-dark,
  .agent-framework-side-panel.theme-dark {
    background: #1a1a1a;
  }

  /* ========== Wrapper Strategy ========== */
  .af-host-wrapper {
    position: fixed;
    top: 0;
    bottom: 0;
    overflow: auto;
    background: inherit;
    z-index: 1; /* Below side panel */
    /* Transform creates containing block for fixed-position descendants */
    transform: translateZ(0);
  }

  .af-host-wrapper.right {
    left: 0;
    right: var(--af-side-width, 400px);
  }

  .af-host-wrapper.left {
    right: 0;
    left: var(--af-side-width, 400px);
  }

  /* Ensure wrapper inherits page background */
  .af-host-wrapper {
    background-color: inherit;
  }

  /* ========== Transform Strategy ========== */
  body.af-transform-strategy {
    transform: scale(1);
    transform-origin: top left;
    overflow-x: hidden;
  }

  body.af-transform-strategy.right {
    width: calc(100vw - var(--af-side-width, 400px));
  }

  body.af-transform-strategy.left {
    width: calc(100vw - var(--af-side-width, 400px));
    margin-left: var(--af-side-width, 400px);
  }

  /* ========== Mobile Full Viewport ========== */

  /* Body scroll lock when mobile fullscreen is open - prevents scroll bleed-through */
  body.agent-framework-mobile-fullscreen {
    overflow: hidden !important;
    position: fixed !important;
    width: 100% !important;
    height: 100% !important;
    /* Prevent iOS overscroll/bounce */
    overscroll-behavior: none;
    touch-action: none;
  }

  /* JS-controlled fullscreen mode for mobile UX (doesn't rely on media query) */
  .agent-framework-floating.ux-mobile {
    top: 0 !important;
    left: 0 !important;
    right: auto !important;
    bottom: auto !important;
  }

  .agent-framework-iframe-wrapper.fullscreen-mobile {
    position: fixed !important;
    top: 0 !important;
    left: 0 !important;
    right: 0 !important;
    bottom: 0 !important;
    /* Use multiple height values for browser compatibility */
    /* Static fallback */
    width: 100% !important;
    height: 100% !important;
    /* Safari -webkit-fill-available */
    height: -webkit-fill-available !important;
    /* Modern browsers: dynamic viewport height (adjusts with Safari address bar) */
    height: 100dvh !important;
    border-radius: 0;
    margin-bottom: 0 !important;
    max-width: none;
    max-height: none;
    min-width: 0;
    min-height: 0;
    /* Override scale animation for fullscreen - just fade in */
    transform: none !important;
    /* Ensure touch events don't propagate */
    touch-action: pan-y;
    overscroll-behavior: contain;
  }

  .agent-framework-iframe-wrapper.fullscreen-mobile .agent-framework-resize-handle {
    display: none;
  }

  .agent-framework-floating.ux-mobile .agent-framework-launcher.open {
    display: none;
  }

  /* Simplify header in fullscreen mobile mode */
  .agent-framework-iframe-wrapper.fullscreen-mobile .agent-framework-dock-btn,
  .agent-framework-iframe-wrapper.fullscreen-mobile .agent-framework-maximize-btn,
  .agent-framework-iframe-wrapper.fullscreen-mobile .agent-framework-close-btn {
    display: none;
  }

  .agent-framework-iframe-wrapper.fullscreen-mobile .agent-framework-drag-handle {
    cursor: default;
  }

  /* Legacy media query fallback (for non-JS scenarios) */
  @media (max-width: 640px) {
    /* Make expanded widget fill the viewport on mobile */
    .agent-framework-iframe-wrapper.visible:not(.fullscreen-mobile) {
      position: fixed !important;
      top: 0 !important;
      left: 0 !important;
      width: 100vw !important;
      height: 100vh !important;
      border-radius: 0;
      margin-bottom: 0 !important;
      max-width: none;
      max-height: none;
      min-width: 0;
      min-height: 0;
    }

    /* Hide resize handle on mobile */
    .agent-framework-iframe-wrapper.visible:not(.fullscreen-mobile) .agent-framework-resize-handle {
      display: none;
    }

    /* Position container at origin for full viewport */
    .agent-framework-floating:not(.ux-mobile) {
      top: 0 !important;
      left: 0 !important;
      right: auto !important;
      bottom: auto !important;
    }

    /* Hide launcher when panel is open on mobile (it would be behind the panel) */
    .agent-framework-floating .agent-framework-launcher.open {
      display: none;
    }

    /* Simplify header buttons on mobile - only show minimize (acts as close) */
    .agent-framework-drag-handle .agent-framework-dock-btn,
    .agent-framework-drag-handle .agent-framework-maximize-btn,
    .agent-framework-drag-handle .agent-framework-close-btn {
      display: none;
    }

    /* Disable dragging the header on mobile (full viewport, no point) */
    .agent-framework-drag-handle {
      cursor: default;
    }
  }
`;var ie='<svg class="chat-icon" viewBox="0 0 24 24"><path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm0 14H6l-2 2V4h16v12z"/></svg>',N='<svg class="close-icon" viewBox="0 0 24 24"><path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/></svg>',ne='<svg viewBox="0 0 24 24"><path d="M19 13H5v-2h14v2z"/></svg>',oe='<svg viewBox="0 0 24 24"><path d="M15.41 7.41L14 6l-6 6 6 6 1.41-1.41L10.83 12z"/></svg>',re='<svg viewBox="0 0 24 24"><path d="M10 6L8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z"/></svg>',K='<svg viewBox="0 0 24 24"><path d="M3 3h18v18H3V3zm2 2v14h14V5H5z"/></svg>',se='<svg viewBox="0 0 24 24"><path d="M4 8h4V4h12v12h-4v4H4V8zm2 2v8h8v-2H8V10H6zm6-4v2h6v6h2V6h-8z"/></svg>',ae='<svg viewBox="0 0 24 24"><path d="M14 19V5h6v14h-6zm-2 2h10V3H12v18zM4 5v14h6V5H4zm-2-2h10v18H2V3z" opacity="0.3"/><path d="M14 5v14h6V5h-6zm8-2v18H12V3h10z"/></svg>',le='<svg viewBox="0 0 24 24"><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V5h14v14z"/><path d="M7 7h6v6H7z"/></svg>';var P={mode:"floating",position:"bottom-right",theme:"system",width:"400px",height:"600px",startOpen:!1,showLauncher:!0,iframeUrl:"/app",zIndex:999999,debug:!1,siteKey:void 0,draggable:!0,persistPosition:!0,initialX:void 0,initialY:void 0,sideWidth:"400px",sideMinWidth:300,sideMaxWidth:80,sideStrategy:"margin",enableDOM:!0,enableMCP:!0,enableToolDiscovery:!1,toolDiscoveryUrl:void 0,newChat:void 0,prompt:void 0,title:"Agent",headerBackground:void 0,headerTextColor:void 0,headerAccentColor:void 0,enableAutoRun:!1,onAutoRunComplete:void 0,autoRunTiming:void 0,ux:"auto",mobileBreakpoint:640,mobileConfig:void 0},W="agent-framework-position";var T=class{constructor(e={}){d(this,"config");d(this,"bridge",null);d(this,"container",null);d(this,"iframe",null);d(this,"wrapper",null);d(this,"launcher",null);d(this,"sideToggle",null);d(this,"dragHandle",null);d(this,"sideHeader",null);d(this,"isOpen",!1);d(this,"isMaximized",!1);d(this,"preMaximizeState",null);d(this,"styleElement",null);d(this,"isDragging",!1);d(this,"dragStartX",0);d(this,"dragStartY",0);d(this,"elementStartX",0);d(this,"elementStartY",0);d(this,"resizeHandle",null);d(this,"isResizing",!1);d(this,"resizeStartX",0);d(this,"resizeStartY",0);d(this,"resizeStartWidth",0);d(this,"resizeStartHeight",0);d(this,"sideSplitter",null);d(this,"isSideDragging",!1);d(this,"sideDragStartX",0);d(this,"sideDragStartWidth",0);d(this,"adjustedFixedElements",new Map);d(this,"hostWrapper",null);d(this,"originalBodyStyles",null);d(this,"pendingThemeRequests",new Map);d(this,"messageListener",null);d(this,"themeReadyReceived",!1);d(this,"themeReadyTimeout",null);d(this,"pendingShow",!1);d(this,"currentStatus","idle");d(this,"dragRafId",null);d(this,"resizeRafId",null);d(this,"sideRafId",null);d(this,"sessionToken",null);d(this,"siteKeyConfig",null);d(this,"currentUxMode","desktop");d(this,"resizeListener",null);d(this,"baseConfig");d(this,"handleLauncherDragStart",e=>{this.isDragging=!1,this.dragStartX=e.clientX,this.dragStartY=e.clientY;let t=this.container.getBoundingClientRect();this.elementStartX=t.left,this.elementStartY=t.top,document.addEventListener("mousemove",this.handleLauncherDragMove),document.addEventListener("mouseup",this.handleLauncherDragEnd)});d(this,"handleLauncherTouchStart",e=>{if(e.touches.length!==1)return;let t=e.touches[0];this.isDragging=!1,this.dragStartX=t.clientX,this.dragStartY=t.clientY;let i=this.container.getBoundingClientRect();this.elementStartX=i.left,this.elementStartY=i.top,document.addEventListener("touchmove",this.handleLauncherTouchMove,{passive:!1}),document.addEventListener("touchend",this.handleLauncherTouchEnd),document.addEventListener("touchcancel",this.handleLauncherTouchEnd)});d(this,"handleDragMove",e=>{this.handleDragMoveCoords(e.clientX,e.clientY)});d(this,"handleLauncherDragMove",e=>{let t=e.clientX-this.dragStartX,i=e.clientY-this.dragStartY;(Math.abs(t)>5||Math.abs(i)>5)&&(this.isDragging=!0,this.launcher?.classList.add("dragging"),this.handleDragMove(e))});d(this,"handleLauncherTouchMove",e=>{if(e.touches.length!==1)return;let t=e.touches[0],i=t.clientX-this.dragStartX,n=t.clientY-this.dragStartY;(Math.abs(i)>5||Math.abs(n)>5)&&(this.isDragging=!0,this.launcher?.classList.add("dragging"),e.preventDefault(),this.handleDragMoveCoords(t.clientX,t.clientY))});d(this,"handleDragEnd",e=>{if(document.removeEventListener("mousemove",this.handleDragMove),document.removeEventListener("mouseup",this.handleDragEnd),this.dragRafId&&(cancelAnimationFrame(this.dragRafId),this.dragRafId=null),this.config.persistPosition&&this.container){let t=this.container.getBoundingClientRect();this.saveState({x:t.left,y:t.top})}this.isDragging=!1});d(this,"handleDragTouchMove",e=>{if(!this.container||e.touches.length!==1)return;e.preventDefault();let t=e.touches[0];this.handleDragMoveCoords(t.clientX,t.clientY)});d(this,"handleDragTouchEnd",e=>{if(document.removeEventListener("touchmove",this.handleDragTouchMove),document.removeEventListener("touchend",this.handleDragTouchEnd),document.removeEventListener("touchcancel",this.handleDragTouchEnd),this.dragRafId&&(cancelAnimationFrame(this.dragRafId),this.dragRafId=null),this.config.persistPosition&&this.container){let t=this.container.getBoundingClientRect();this.saveState({x:t.left,y:t.top})}this.isDragging=!1});d(this,"handleLauncherDragEnd",e=>{if(document.removeEventListener("mousemove",this.handleLauncherDragMove),document.removeEventListener("mouseup",this.handleLauncherDragEnd),this.launcher?.classList.remove("dragging"),this.isDragging&&this.config.persistPosition&&this.container){let t=this.container.getBoundingClientRect();this.saveState({x:t.left,y:t.top})}setTimeout(()=>{this.isDragging=!1},10)});d(this,"handleLauncherTouchEnd",e=>{if(document.removeEventListener("touchmove",this.handleLauncherTouchMove),document.removeEventListener("touchend",this.handleLauncherTouchEnd),document.removeEventListener("touchcancel",this.handleLauncherTouchEnd),this.launcher?.classList.remove("dragging"),this.isDragging&&this.config.persistPosition&&this.container){let t=this.container.getBoundingClientRect();this.saveState({x:t.left,y:t.top})}setTimeout(()=>{this.isDragging=!1},10)});d(this,"handleResizeMove",e=>{if(!this.wrapper||!this.isResizing||this.resizeRafId)return;let t=e.clientX,i=e.clientY;this.resizeRafId=requestAnimationFrame(()=>{if(this.resizeRafId=null,!this.wrapper||!this.isResizing)return;let n=t-this.resizeStartX,r=i-this.resizeStartY,s=Math.max(300,this.resizeStartWidth+n),l=Math.max(400,this.resizeStartHeight+r);this.wrapper.style.width=`${s}px`,this.wrapper.style.height=`${l}px`})});d(this,"handleResizeEnd",e=>{if(document.removeEventListener("mousemove",this.handleResizeMove),document.removeEventListener("mouseup",this.handleResizeEnd),this.resizeRafId&&(cancelAnimationFrame(this.resizeRafId),this.resizeRafId=null),this.config.persistPosition&&this.container&&this.wrapper){let t=this.container.getBoundingClientRect();this.saveState({x:t.left,y:t.top,width:this.wrapper.offsetWidth,height:this.wrapper.offsetHeight})}this.isResizing=!1});d(this,"handleSideSplitterDragMove",e=>{if(!this.isSideDragging||!this.container||this.sideRafId)return;let t=e.clientX;this.sideRafId=requestAnimationFrame(()=>{if(this.sideRafId=null,!this.isSideDragging||!this.container)return;let i=this.config.position==="left"?"left":"right",n=window.innerWidth,r;i==="right"?r=n-t:r=t;let s=this.config.sideMinWidth??300,l=(this.config.sideMaxWidth??80)/100*n;r=Math.max(s,Math.min(l,r));let a=`${r}px`;document.body.style.setProperty("--af-side-width",a),this.container.style.width=a,this.updateSideStrategy(r)})});d(this,"handleSideSplitterDragEnd",e=>{if(document.removeEventListener("mousemove",this.handleSideSplitterDragMove),document.removeEventListener("mouseup",this.handleSideSplitterDragEnd),this.sideRafId&&(cancelAnimationFrame(this.sideRafId),this.sideRafId=null),this.container?.classList.remove("resizing"),this.sideSplitter?.classList.remove("dragging"),this.config.persistPosition&&this.container){let t=`${this.container.offsetWidth}px`;this.saveState({sideWidth:t})}this.isSideDragging=!1});this.baseConfig=e,this.config={...P,...e},this.config.container&&!e.mode&&(this.config.mode="container"),this.applyUxModeConfig()}getEffectiveUxMode(){let e=this.config.ux??"auto";return e==="mobile"?"mobile":e==="desktop"?"desktop":this.isMobileViewport()?"mobile":"desktop"}applyUxModeConfig(){let e=this.getEffectiveUxMode();if(!(e===this.currentUxMode&&this.currentUxMode==="desktop"))if(this.currentUxMode=e,this.log("UX mode determined",{mode:e}),e==="mobile"){this.config={...P,...this.baseConfig};let t={width:"100%",height:"100%",draggable:!1,showLauncher:!0,mode:this.config.mode==="side"?"floating":this.config.mode};this.config={...this.config,...t},this.baseConfig.mobileConfig&&(this.config={...this.config,...this.baseConfig.mobileConfig},this.log("Applied mobileConfig overrides",this.baseConfig.mobileConfig)),this.config.mode==="side"&&(this.config.mode="floating",this.log("Forced mode to floating (side not supported on mobile)"))}else this.config={...P,...this.baseConfig}}setupResizeListener(){if(this.config.ux!=="auto")return;let e=null;this.resizeListener=()=>{e&&clearTimeout(e),e=setTimeout(()=>{this.handleViewportResize()},150)},window.addEventListener("resize",this.resizeListener),this.log("Resize listener set up for auto UX mode")}handleViewportResize(){let e=this.getEffectiveUxMode();if(e===this.currentUxMode)return;this.log("UX mode change detected",{from:this.currentUxMode,to:e});let t=this.isOpen;this.rebuildForUxModeChange(e,t)}async rebuildForUxModeChange(e,t){switch(this.container?.remove(),this.sideToggle?.remove(),this.launcher?.remove(),this.config.mode==="side"&&(this.cleanupSideStrategy(),document.body.style.removeProperty("--af-side-width")),this.container=null,this.wrapper=null,this.launcher=null,this.sideToggle=null,this.dragHandle=null,this.sideSplitter=null,this.resizeHandle=null,this.sideHeader=null,this.iframe=null,this.isOpen=!1,this.isMaximized=!1,this.preMaximizeState=null,this.currentUxMode=e,this.applyUxModeConfig(),this.config.mode){case"container":await this.createInlineEmbed();break;case"side":await this.createSidePanel();break;case"hidden":await this.createHiddenEmbed();break;case"floating":default:await this.createFloatingWidget();break}t&&this.show(),this.log("UI rebuilt for UX mode change",{mode:this.config.mode,ux:e})}async validateSiteKey(){if(window.__ripulNativeToken)return{valid:!0,sessionToken:window.__ripulNativeToken,config:window.__ripulNativeConfig||{}};if(!this.config.siteKey)return{valid:!1,error:{code:"INVALID_KEY",message:"No site key provided"}};return{valid:!0,sessionToken:null,config:{}}}showValidationError(e){let i={INVALID_KEY:"Invalid Site Key",DISABLED:"Site Key Disabled",ORIGIN_NOT_ALLOWED:"Domain Not Authorized",EXPIRED:"Site Key Expired",RATE_LIMIT_EXCEEDED:"Rate Limit Exceeded"}[e.code]||"Configuration Error",n=document.createElement("div");n.className="agent-framework-error",n.innerHTML=`
      <div class="agent-framework-error-content">
        <div class="agent-framework-error-icon">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="12" r="10"></circle>
            <line x1="12" y1="8" x2="12" y2="12"></line>
            <line x1="12" y1="16" x2="12.01" y2="16"></line>
          </svg>
        </div>
        <div class="agent-framework-error-text">
          <div class="agent-framework-error-title">${this.escapeHtml(i)}</div>
          <div class="agent-framework-error-message">${this.escapeHtml(e.message)}</div>
          <div class="agent-framework-error-origin">Origin: ${this.escapeHtml(window.location.origin)}</div>
        </div>
      </div>
    `,n.style.cssText=`
      position: fixed;
      bottom: 20px;
      right: 20px;
      z-index: ${this.config.zIndex};
      background: #1a1a1a;
      border: 1px solid #333;
      border-radius: 12px;
      padding: 16px 20px;
      max-width: 360px;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
    `;let r=n.querySelector(".agent-framework-error-content");r&&(r.style.cssText="display: flex; gap: 12px; align-items: flex-start;");let s=n.querySelector(".agent-framework-error-icon");s&&(s.style.cssText="color: #ef4444; flex-shrink: 0;");let l=n.querySelector(".agent-framework-error-title");l&&(l.style.cssText="color: #fff; font-weight: 600; font-size: 14px; margin-bottom: 4px;");let a=n.querySelector(".agent-framework-error-message");a&&(a.style.cssText="color: #999; font-size: 13px; line-height: 1.4;");let c=n.querySelector(".agent-framework-error-origin");c&&(c.style.cssText="color: #666; font-size: 11px; margin-top: 8px; font-family: monospace;"),document.body.appendChild(n),this.container=n,this.log("Site key validation failed",{code:e.code,message:e.message,origin:window.location.origin})}async init(){try{if(this.injectStyles(),this.config.siteKey){this.log("Validating site key from host page",{origin:window.location.origin});let s=await this.validateSiteKey();if(!s.valid){this.showValidationError(s.error||{code:"INVALID_KEY",message:"Validation failed"});let l={show:()=>{},hide:()=>{},toggle:()=>{},isVisible:()=>!1,maximize:()=>{},restore:()=>{},toggleMaximize:()=>{},isMaximized:()=>!1,destroy:()=>{this.destroy()},getIframe:()=>null,postMessage:()=>{},setTheme:async()=>{},updateHeader:()=>{},setStatus:()=>{},getStatus:()=>"idle"};return this.config.onError?.(new Error(s.error?.message||"Site key validation failed")),l}this.sessionToken=s.sessionToken||null,this.siteKeyConfig=s.config||null,this.log("Site key validated successfully",{hasToken:!!this.sessionToken})}this.setupMessageListener();let e={...this.config.bridge,enableDOM:this.config.enableDOM??this.config.bridge?.enableDOM,enableMCP:this.config.enableMCP??this.config.bridge?.enableMCP,enableToolDiscovery:this.config.enableToolDiscovery??this.config.bridge?.enableToolDiscovery,toolDiscoveryUrl:this.config.toolDiscoveryUrl??this.config.bridge?.toolDiscoveryUrl,debug:this.config.debug,enableAutoRun:this.config.enableAutoRun??this.config.bridge?.enableAutoRun,autoRunTiming:this.config.autoRunTiming??this.config.bridge?.autoRunTiming,onAutoRunComplete:this.config.onAutoRunComplete??this.config.bridge?.onAutoRunComplete};if(this.log("Creating bridge with config",{enableDOM:e.enableDOM,enableMCP:e.enableMCP,enableToolDiscovery:e.enableToolDiscovery,configEnableDOM:this.config.enableDOM,bridgeEnableDOM:this.config.bridge?.enableDOM}),this.bridge=z.getInstance(e),this.bridge.init(),this.config.persistPosition&&this.config.mode!=="container"&&this.config.mode!=="hidden"){let s=this.loadState();s?.mode&&s.mode!==this.config.mode&&(s.mode==="side"&&this.currentUxMode==="mobile"?this.log("Ignoring saved side mode on mobile UX",{savedMode:s.mode,uxMode:this.currentUxMode}):(this.config.mode=s.mode,s.mode==="side"&&(this.config.position="right"),this.log("Restored saved mode",{mode:s.mode})))}switch(this.config.mode){case"container":await this.createInlineEmbed();break;case"side":await this.createSidePanel();break;case"hidden":await this.createHiddenEmbed();break;case"floating":default:await this.createFloatingWidget();break}let t=this.createAPI(),i=this.config.persistPosition?this.loadState():null,n=this.currentUxMode==="mobile"?!1:i?.isOpen??!1,r=this.config.mode!=="hidden"&&(this.config.startOpen||n);return this.currentUxMode==="mobile"&&i?.isOpen&&this.log("Ignoring saved isOpen state on mobile UX - user must explicitly open"),r&&(this.config.siteKey?(this.pendingShow=!0,this.log("Site key mode: waiting for theme:ready before showing"),this.themeReadyTimeout=setTimeout(()=>{this.pendingShow&&(this.log("Theme ready timeout - showing widget anyway"),this.pendingShow=!1,this.show())},3e3)):t.show()),this.setupResizeListener(),this.config.onReady?.(t),this.log("Embed initialized",{mode:this.config.mode,ux:this.currentUxMode}),t}catch(e){let t=e instanceof Error?e:new Error(String(e));throw this.config.onError?.(t),t}}async createInlineEmbed(){let e=typeof this.config.container=="string"?document.querySelector(this.config.container):this.config.container;if(!e)throw new Error(`Container not found: ${this.config.container}`);this.container=e,this.container.classList.add("agent-framework-container"),this.iframe=this.createIframe(),this.iframe.style.width=this.config.width,this.iframe.style.height=this.config.height,this.container.appendChild(this.iframe),this.isOpen=!0}async createHiddenEmbed(){this.container=document.createElement("div"),this.container.className="agent-framework-container agent-framework-hidden",this.container.style.cssText=`
      position: absolute !important;
      width: 1px !important;
      height: 1px !important;
      padding: 0 !important;
      margin: -1px !important;
      overflow: hidden !important;
      clip: rect(0, 0, 0, 0) !important;
      white-space: nowrap !important;
      border: 0 !important;
    `,this.iframe=this.createIframe(),this.iframe.style.width="1px",this.iframe.style.height="1px",this.iframe.setAttribute("aria-hidden","true"),this.iframe.setAttribute("tabindex","-1"),this.container.appendChild(this.iframe),document.body.appendChild(this.container),this.isOpen=!0,this.log("Hidden embed created (infrastructure only, no UI)")}async createFloatingWidget(){this.container=document.createElement("div"),this.container.className="agent-framework-container agent-framework-floating",this.container.style.setProperty("--af-z-index",String(this.config.zIndex)),this.currentUxMode==="mobile"&&this.container.classList.add("ux-mobile");let e=this.config.persistPosition?this.loadPosition():null;if(e||this.config.initialX!==void 0||this.config.initialY!==void 0){this.container.classList.add("custom-position");let c=e?.x??this.config.initialX??window.innerWidth-420,f=e?.y??this.config.initialY??window.innerHeight-680,y=parseInt(this.config.width,10)||400,h=parseInt(this.config.height,10)||600,{x:g,y:m}=this.clampToViewport(c,f,y,h);this.container.style.left=`${g}px`,this.container.style.top=`${m}px`}else this.container.classList.add(this.config.position);this.wrapper=document.createElement("div"),this.wrapper.className=`agent-framework-iframe-wrapper theme-${this.config.theme}`,this.wrapper.style.width=this.config.width,this.wrapper.style.height=this.config.height,this.wrapper.style.marginBottom=this.config.showLauncher?"70px":"0",this.dragHandle=document.createElement("div"),this.dragHandle.className="agent-framework-drag-handle",this.dragHandle.innerHTML=`
      <span class="agent-framework-drag-handle-title">${this.escapeHtml(this.config.title)}</span>
      <div class="agent-framework-drag-handle-buttons">
        <button class="agent-framework-dock-btn" title="Dock to side">${ae}</button>
        <button class="agent-framework-minimize-btn" title="Minimize">${ne}</button>
        <button class="agent-framework-maximize-btn" title="Maximize">${K}</button>
        <button class="agent-framework-close-btn" title="Close">${N}</button>
      </div>
    `,this.applyHeaderStyles(this.dragHandle),this.wrapper.appendChild(this.dragHandle),this.config.draggable&&(this.dragHandle.addEventListener("mousedown",this.handleDragStart.bind(this)),this.dragHandle.addEventListener("touchstart",this.handleDragTouchStart.bind(this),{passive:!0})),this.dragHandle.querySelector(".agent-framework-minimize-btn")?.addEventListener("click",c=>{c.stopPropagation(),this.hide()}),this.dragHandle.querySelector(".agent-framework-maximize-btn")?.addEventListener("click",c=>{c.stopPropagation(),this.toggleMaximize()}),this.dragHandle.querySelector(".agent-framework-close-btn")?.addEventListener("click",c=>{c.stopPropagation(),this.hide()}),this.dragHandle.querySelector(".agent-framework-dock-btn")?.addEventListener("click",c=>{c.stopPropagation(),this.switchMode("side")});let l=document.createElement("div");l.style.height="calc(100% - 32px)",this.iframe=this.createIframe(),l.appendChild(this.iframe),this.wrapper.appendChild(l),this.resizeHandle=document.createElement("div"),this.resizeHandle.className="agent-framework-resize-handle",this.resizeHandle.addEventListener("mousedown",this.handleResizeStart.bind(this)),this.wrapper.appendChild(this.resizeHandle),this.container.appendChild(this.wrapper);let a=this.config.persistPosition?this.loadState():null;a?.width&&a?.height&&(this.wrapper.style.width=`${a.width}px`,this.wrapper.style.height=`${a.height}px`),a?.isMaximized&&(this.preMaximizeState={x:a.x??0,y:a.y??0,width:a.width??(parseInt(this.config.width,10)||400),height:a.height??(parseInt(this.config.height,10)||600)},setTimeout(()=>this.maximize(),0)),this.config.showLauncher&&(this.launcher=document.createElement("button"),this.launcher.className="agent-framework-launcher",this.config.draggable&&(this.launcher.classList.add("draggable"),this.launcher.addEventListener("mousedown",this.handleLauncherDragStart.bind(this)),this.launcher.addEventListener("touchstart",this.handleLauncherTouchStart.bind(this),{passive:!0})),this.launcher.innerHTML=ie+N,this.launcher.addEventListener("click",()=>{this.isDragging||this.toggle()}),this.container.appendChild(this.launcher)),document.body.appendChild(this.container)}async createSidePanel(){let e=this.config.position==="left"?"left":"right",i=(this.config.persistPosition?this.loadState():null)?.sideWidth??this.config.sideWidth;document.body.style.setProperty("--af-side-width",i),this.container=document.createElement("div"),this.container.className=`agent-framework-container agent-framework-side-panel ${e} theme-${this.config.theme}`,this.container.style.setProperty("--af-z-index",String(this.config.zIndex)),this.container.style.width=i,this.sideHeader=document.createElement("div"),this.sideHeader.className="agent-framework-side-header",this.sideHeader.innerHTML=`
      <span class="agent-framework-side-header-title">${this.escapeHtml(this.config.title)}</span>
      <div class="agent-framework-side-header-buttons">
        <button class="agent-framework-float-btn" title="Float window">${le}</button>
        <button class="agent-framework-close-btn" title="Close">${N}</button>
      </div>
    `,this.applyHeaderStyles(this.sideHeader),this.container.appendChild(this.sideHeader);let n=this.sideHeader;n.querySelector(".agent-framework-float-btn")?.addEventListener("click",a=>{a.stopPropagation(),this.switchMode("floating")}),n.querySelector(".agent-framework-close-btn")?.addEventListener("click",a=>{a.stopPropagation(),this.hide()}),this.sideSplitter=document.createElement("div"),this.sideSplitter.className="agent-framework-side-splitter",this.sideSplitter.addEventListener("mousedown",this.handleSideSplitterDragStart.bind(this)),this.container.appendChild(this.sideSplitter);let l=document.createElement("div");l.className="agent-framework-side-iframe-container",this.iframe=this.createIframe(),l.appendChild(this.iframe),this.container.appendChild(l),this.sideToggle=document.createElement("button"),this.sideToggle.className=`agent-framework-side-toggle ${e}`,this.sideToggle.innerHTML=e==="right"?oe:re,this.sideToggle.addEventListener("click",()=>this.toggle()),document.body.appendChild(this.container),document.body.appendChild(this.sideToggle)}handleDragStart(e){if(e.target.closest("button"))return;this.isDragging=!0,this.dragStartX=e.clientX,this.dragStartY=e.clientY;let t=this.container.getBoundingClientRect();this.elementStartX=t.left,this.elementStartY=t.top,document.addEventListener("mousemove",this.handleDragMove),document.addEventListener("mouseup",this.handleDragEnd),e.preventDefault()}handleDragMoveCoords(e,t){this.container&&(this.dragRafId||(this.dragRafId=requestAnimationFrame(()=>{if(this.dragRafId=null,!this.container)return;let i=e-this.dragStartX,n=t-this.dragStartY,r=Math.max(0,Math.min(this.elementStartX+i,window.innerWidth-this.container.offsetWidth)),s=Math.max(0,Math.min(this.elementStartY+n,window.innerHeight-this.container.offsetHeight));this.container.classList.remove("bottom-right","bottom-left","top-right","top-left","center"),this.container.classList.add("custom-position"),this.container.style.left=`${r}px`,this.container.style.top=`${s}px`})))}handleDragTouchStart(e){if(e.target.closest("button")||e.touches.length!==1)return;let t=e.touches[0];this.isDragging=!0,this.dragStartX=t.clientX,this.dragStartY=t.clientY;let i=this.container.getBoundingClientRect();this.elementStartX=i.left,this.elementStartY=i.top,document.addEventListener("touchmove",this.handleDragTouchMove,{passive:!1}),document.addEventListener("touchend",this.handleDragTouchEnd),document.addEventListener("touchcancel",this.handleDragTouchEnd)}handleResizeStart(e){this.isResizing=!0,this.resizeStartX=e.clientX,this.resizeStartY=e.clientY,this.resizeStartWidth=this.wrapper?.offsetWidth??400,this.resizeStartHeight=this.wrapper?.offsetHeight??600,document.addEventListener("mousemove",this.handleResizeMove),document.addEventListener("mouseup",this.handleResizeEnd),e.preventDefault(),e.stopPropagation()}handleSideSplitterDragStart(e){this.isSideDragging=!0,this.sideDragStartX=e.clientX,this.sideDragStartWidth=this.container?.offsetWidth??400,this.container?.classList.add("resizing"),this.sideSplitter?.classList.add("dragging"),document.addEventListener("mousemove",this.handleSideSplitterDragMove),document.addEventListener("mouseup",this.handleSideSplitterDragEnd),e.preventDefault()}adjustFixedElements(e){if(this.config.mode!=="side")return;let t=this.config.position==="left"?"left":"right";document.querySelectorAll('header, footer, nav, [role="banner"], [role="navigation"], [class*="fixed"], [class*="sticky"], [class*="header"], [class*="footer"], [class*="navbar"], [class*="nav-bar"], [class*="toolbar"], [class*="appbar"]').forEach(n=>{n===this.container||n===this.sideToggle||n===this.sideSplitter||!(n instanceof HTMLElement)||window.getComputedStyle(n).position!=="fixed"||!(n.getBoundingClientRect().width>=window.innerWidth*.9)||(this.adjustedFixedElements.has(n)||this.adjustedFixedElements.set(n,{originalRight:n.style.right,originalWidth:n.style.width}),t==="right"?n.style.right=`${e}px`:n.style.left=`${e}px`)})}restoreFixedElements(){let e=this.config.position==="left"?"left":"right";this.adjustedFixedElements.forEach((t,i)=>{e==="right"?i.style.right=t.originalRight:i.style.left=t.originalRight}),this.adjustedFixedElements.clear()}updateFixedElements(e){let t=this.config.position==="left"?"left":"right";this.adjustedFixedElements.forEach((i,n)=>{t==="right"?n.style.right=`${e}px`:n.style.left=`${e}px`})}applySideStrategy(e){switch(this.config.sideStrategy??"margin"){case"wrapper":this.applyWrapperStrategy(e);break;case"transform":this.applyTransformStrategy(e);break;case"margin":default:this.applyMarginStrategy(e);break}}applyMarginStrategy(e){let t=this.config.position==="left"?"left":"right";document.body.classList.add(`agent-framework-side-open-${t}`);let i=parseInt(e,10)||400;this.adjustFixedElements(i)}applyWrapperStrategy(e){let t=this.config.position==="left"?"left":"right";this.hostWrapper=document.createElement("div"),this.hostWrapper.className=`af-host-wrapper ${t}`;let i=Array.from(document.body.children);for(let n of i)n===this.container||n===this.sideToggle||n===this.styleElement||n.tagName==="SCRIPT"||this.hostWrapper.appendChild(n);document.body.insertBefore(this.hostWrapper,document.body.firstChild)}applyTransformStrategy(e){let t=this.config.position==="left"?"left":"right";this.originalBodyStyles={transform:document.body.style.transform,width:document.body.style.width,marginLeft:document.body.style.marginLeft},document.body.classList.add("af-transform-strategy",t)}cleanupSideStrategy(){switch(this.config.sideStrategy??"margin"){case"wrapper":this.cleanupWrapperStrategy();break;case"transform":this.cleanupTransformStrategy();break;case"margin":default:this.cleanupMarginStrategy();break}}cleanupMarginStrategy(){document.body.classList.remove("agent-framework-side-open-left","agent-framework-side-open-right"),this.restoreFixedElements()}cleanupWrapperStrategy(){if(!this.hostWrapper)return;let e=Array.from(this.hostWrapper.children);for(let t of e)document.body.appendChild(t);this.hostWrapper.remove(),this.hostWrapper=null}cleanupTransformStrategy(){document.body.classList.remove("af-transform-strategy","left","right"),this.originalBodyStyles&&(document.body.style.transform=this.originalBodyStyles.transform,document.body.style.width=this.originalBodyStyles.width,document.body.style.marginLeft=this.originalBodyStyles.marginLeft,this.originalBodyStyles=null)}updateSideStrategy(e){switch(this.config.sideStrategy??"margin"){case"wrapper":break;case"transform":break;case"margin":default:this.updateFixedElements(e);break}}saveState(e){try{let i={...this.loadState()??{},...e};localStorage.setItem(W,JSON.stringify(i)),this.log("State saved",i)}catch{}}loadState(){try{let e=localStorage.getItem(W);if(e){let t=JSON.parse(e);if(t.x!==void 0&&t.y!==void 0){let i=window.innerWidth,n=window.innerHeight;if(t.x>i+100||t.y>n+100||t.x<-500||t.y<-500)return this.log("Saved position invalid, resetting",{x:t.x,y:t.y,vw:i,vh:n}),localStorage.removeItem(W),null}return t}}catch{}return null}loadPosition(){let e=this.loadState();return e&&e.x!==void 0&&e.y!==void 0?{x:e.x,y:e.y}:null}clampToViewport(e,t,i,n,r=100){let s=window.innerWidth,l=window.innerHeight,a=Math.max(0,s-Math.min(i,r)),c=Math.max(0,l-Math.min(n,r)),f=Math.max(0,Math.min(e,a)),y=Math.max(0,Math.min(t,c));return{x:f,y}}createIframe(){let e=document.createElement("iframe");return e.className="agent-framework-iframe",e.src=this.resolveIframeUrl(),e.allow="clipboard-write",e.setAttribute("loading","lazy"),e}resolveIframeUrl(){let e=this.config.iframeUrl,t;if(e.startsWith("http://")||e.startsWith("https://"))t=e;else{let l=null,a=document.currentScript;if(a?.src)l=new URL(a.src).origin;else{let c=document.querySelectorAll('script[src*="embed.js"]');if(c.length>0){let f=c[c.length-1];f.src&&(l=new URL(f.src).origin)}}l?t=new URL(e,l).href:(this.log("Warning: Could not determine embed script origin, using current origin"),t=new URL(e,window.location.origin).href)}let i=new URL(t),n=new URLSearchParams;if(n.set("embedded","true"),this.config.siteKey)if(n.set("siteKey",this.config.siteKey),n.set("skipOnboarding","true"),this.sessionToken){if(n.set("sessionToken",this.sessionToken),this.siteKeyConfig)try{n.set("siteKeyConfig",encodeURIComponent(JSON.stringify(this.siteKeyConfig)))}catch(l){this.log("Failed to serialize site key config",{error:l})}this.log("Site key mode enabled with pre-validated token",{siteKey:this.config.siteKey.substring(0,12)+"..."})}else this.log("Site key mode enabled (no pre-validated token)",{siteKey:this.config.siteKey.substring(0,12)+"..."});this.config.newChat&&(n.set("newChat","true"),this.log("New chat mode enabled")),this.config.prompt&&(n.set("prompt",this.config.prompt),this.config.newChat||n.set("newChat","true"),this.log("Prompt mode enabled",{promptLength:this.config.prompt.length}));let r=i.hash||"#/",s=r.indexOf("?");if(s!==-1){let l=new URLSearchParams(r.substring(s+1));n.forEach((a,c)=>l.set(c,a)),r=r.substring(0,s)+"?"+l.toString()}else r=r+"?"+n.toString();return i.hash=r,this.log("Resolved iframe URL",{url:i.href}),i.href}injectStyles(){this.styleElement||(this.styleElement=document.createElement("style"),this.styleElement.textContent=te,document.head.appendChild(this.styleElement))}show(){if(this.config.mode==="side"){this.container?.classList.add("visible"),this.sideToggle?.classList.add("visible");let e=this.container?.style.width??this.config.sideWidth;this.applySideStrategy(e)}else this.wrapper&&(this.wrapper.classList.add("visible"),this.currentUxMode==="mobile"&&(this.wrapper.classList.add("fullscreen-mobile"),document.body.classList.add("agent-framework-mobile-fullscreen"))),this.launcher&&this.launcher.classList.add("open");this.isOpen=!0,this.config.persistPosition&&this.saveState({isOpen:!0})}hide(){this.config.mode==="side"?(this.container?.classList.remove("visible"),this.sideToggle?.classList.remove("visible"),this.cleanupSideStrategy()):(this.wrapper&&(this.wrapper.classList.remove("visible"),this.wrapper.classList.remove("fullscreen-mobile")),document.body.classList.remove("agent-framework-mobile-fullscreen"),this.launcher&&this.launcher.classList.remove("open")),this.isOpen=!1,this.config.persistPosition&&this.saveState({isOpen:!1})}toggle(){this.isOpen?this.hide():this.show()}toggleMaximize(){this.isMaximized?this.restore():this.maximize()}maximize(){if(this.config.mode!=="floating"||!this.wrapper||!this.container)return;let e=this.container.getBoundingClientRect();this.preMaximizeState={x:e.left,y:e.top,width:this.wrapper.offsetWidth,height:this.wrapper.offsetHeight},this.wrapper.classList.add("maximized"),this.container.classList.add("custom-position"),this.container.classList.remove("bottom-right","bottom-left","top-right","top-left","center"),this.container.style.left="0px",this.container.style.top="0px",this.launcher&&(this.launcher.style.display="none");let t=this.dragHandle?.querySelector(".agent-framework-maximize-btn");t&&(t.innerHTML=se,t.setAttribute("title","Restore")),this.isMaximized=!0,this.config.persistPosition&&this.saveState({isMaximized:!0})}restore(){if(this.config.mode!=="floating"||!this.wrapper||!this.container)return;this.wrapper.classList.remove("maximized"),this.preMaximizeState&&(this.container.style.left=`${this.preMaximizeState.x}px`,this.container.style.top=`${this.preMaximizeState.y}px`,this.wrapper.style.width=`${this.preMaximizeState.width}px`,this.wrapper.style.height=`${this.preMaximizeState.height}px`),this.launcher&&(this.launcher.style.display="");let e=this.dragHandle?.querySelector(".agent-framework-maximize-btn");e&&(e.innerHTML=K,e.setAttribute("title","Maximize")),this.isMaximized=!1,this.preMaximizeState=null,this.config.persistPosition&&this.saveState({isMaximized:!1})}isMobileViewport(){let e=this.config.mobileBreakpoint??640;return window.innerWidth<=e}async switchMode(e){if(this.config.mode!==e){if(e==="side"&&this.isMobileViewport()){this.log("Ignoring switch to side mode on mobile viewport");return}this.log("Switching mode",{from:this.config.mode,to:e}),this.config.persistPosition&&this.saveState({mode:e}),this.container?.remove(),this.sideToggle?.remove(),this.launcher?.remove(),this.config.mode==="side"&&(this.cleanupSideStrategy(),document.body.style.removeProperty("--af-side-width")),this.container=null,this.wrapper=null,this.launcher=null,this.sideToggle=null,this.dragHandle=null,this.sideSplitter=null,this.resizeHandle=null,this.iframe=null,this.config.mode=e,e==="side"&&(this.config.position="right"),e==="side"?(await this.createSidePanel(),this.applySideStrategy(this.config.sideWidth)):await this.createFloatingWidget(),this.show()}}destroy(){this.bridge?.destroy(),this.container?.remove(),this.sideToggle?.remove(),this.styleElement?.remove(),this.config.mode==="side"&&this.cleanupSideStrategy(),document.body.style.removeProperty("--af-side-width"),document.body.classList.remove("agent-framework-mobile-fullscreen"),this.isSideDragging&&(document.removeEventListener("mousemove",this.handleSideSplitterDragMove),document.removeEventListener("mouseup",this.handleSideSplitterDragEnd)),this.resizeListener&&(window.removeEventListener("resize",this.resizeListener),this.resizeListener=null),this.messageListener&&(window.removeEventListener("message",this.messageListener),this.messageListener=null),this.themeReadyTimeout&&(clearTimeout(this.themeReadyTimeout),this.themeReadyTimeout=null),this.pendingThemeRequests.forEach(e=>{e.reject(new Error("Widget destroyed"))}),this.pendingThemeRequests.clear(),this.iframe=null,this.container=null,this.wrapper=null,this.launcher=null,this.sideToggle=null,this.dragHandle=null,this.sideSplitter=null,this.hostWrapper=null,this.styleElement=null}createAPI(){return{show:()=>this.show(),hide:()=>this.hide(),toggle:()=>this.toggle(),isVisible:()=>this.isOpen,maximize:()=>this.maximize(),restore:()=>this.restore(),toggleMaximize:()=>this.toggleMaximize(),isMaximized:()=>this.isMaximized,destroy:()=>this.destroy(),getIframe:()=>this.iframe,postMessage:e=>{this.iframe?.contentWindow&&this.iframe.contentWindow.postMessage(e,"*")},setTheme:e=>this.setTheme(e),updateHeader:e=>this.updateHeader(e),setStatus:e=>this.setStatus(e),getStatus:()=>this.getStatus()}}setupMessageListener(){this.messageListener=e=>{if(!O(e.data))return;let t=e.data;if(t.type===`${E}theme:set:ack`){let i=t,n=this.pendingThemeRequests.get(i.requestId);n&&(this.pendingThemeRequests.delete(i.requestId),i.success?n.resolve():n.reject(new Error("Failed to apply theme")))}if(t.type===`${E}header:update`){let i=t;this.updateHeader({title:i.title,background:i.background,textColor:i.textColor,accentColor:i.accentColor})}if(t.type===`${E}theme:ready`&&this.handleThemeReady(),t.type===`${E}status:update`){let i=t;this.handleStatusUpdate(i.status)}},window.addEventListener("message",this.messageListener)}handleThemeReady(){this.log("Received theme:ready signal from iframe"),this.themeReadyReceived=!0,this.themeReadyTimeout&&(clearTimeout(this.themeReadyTimeout),this.themeReadyTimeout=null),this.pendingShow&&(this.pendingShow=!1,this.show())}handleStatusUpdate(e){this.log("Status update received",{status:e}),this.setStatus(e)}setStatus(e){this.currentStatus!==e&&(this.currentStatus=e,this.launcher&&(this.launcher.classList.remove("status-idle","status-active","status-waiting"),this.launcher.classList.add(`status-${e}`),this.log("Launcher status updated",{status:e})))}getStatus(){return this.currentStatus}async setTheme(e){if(!this.iframe?.contentWindow)throw new Error("Iframe not initialized");let t=`theme-${Date.now()}-${Math.random().toString(36).slice(2)}`;return new Promise((i,n)=>{let r=setTimeout(()=>{this.pendingThemeRequests.delete(t),n(new Error("Theme change request timed out"))},5e3);this.pendingThemeRequests.set(t,{resolve:()=>{clearTimeout(r),i()},reject:l=>{clearTimeout(r),n(l)}});let s={type:`${E}theme:set`,version:G,timestamp:Date.now(),requestId:t,theme:e};this.iframe.contentWindow.postMessage(s,"*"),this.log("Sent theme change request",{theme:e,requestId:t})})}escapeHtml(e){let t=document.createElement("div");return t.textContent=e,t.innerHTML}applyHeaderStyles(e){if(this.config.headerBackground&&(e.style.background=this.config.headerBackground),this.config.headerTextColor){e.style.color=this.config.headerTextColor;let t=e.querySelector(".agent-framework-drag-handle-title, .agent-framework-side-header-title");t&&(t.style.color=this.config.headerTextColor)}if(this.config.headerAccentColor||this.config.headerTextColor){let t=this.config.headerAccentColor||this.config.headerTextColor;e.querySelectorAll("button").forEach(n=>{n.style.color=t})}}updateHeader(e){if(this.log("Updating header",e),e.title!==void 0&&(this.config.title=e.title),e.background!==void 0&&(this.config.headerBackground=e.background),e.textColor!==void 0&&(this.config.headerTextColor=e.textColor),e.accentColor!==void 0&&(this.config.headerAccentColor=e.accentColor),this.dragHandle){let t=this.dragHandle.querySelector(".agent-framework-drag-handle-title");t&&e.title!==void 0&&(t.textContent=e.title),this.applyHeaderStyles(this.dragHandle)}if(this.sideHeader){let t=this.sideHeader.querySelector(".agent-framework-side-header-title");t&&e.title!==void 0&&(t.textContent=e.title),this.applyHeaderStyles(this.sideHeader)}this.launcher&&e.background&&(this.launcher.style.background=e.background,this.launcher.style.boxShadow=`0 4px 12px ${e.background}66`)}log(e,t){this.config.debug&&console.log(`[AgentFramework] ${e}`,t??"")}};var A=null,M=null,X=null,R=null;async function L(o={},e={}){let t=e.debug??o.debug??!1,i=e.source??"unknown";if(t&&console.log(`[AgentFramework:init] Initializing from source: ${i}`),A){let r=!R?.siteKey&&o.siteKey;if(e.force||r)t&&console.log(`[AgentFramework:init] Re-initializing: ${r?"upgrading config (siteKey added)":"force flag"}`),D();else return R?.siteKey===o.siteKey&&R?.mode===(o.mode||"floating")&&R?.position===(o.position||"bottom-right")?(t&&console.log("[AgentFramework:init] Already initialized with same config, returning existing instance"),M):(console.warn(`[AgentFramework:init] Already initialized from "${X}". Use { force: true } to re-initialize or call destroyAgentFramework() first.`),M)}let n=U(o);return t&&console.log("[AgentFramework:init] Normalized config:",n),A=new T(n),M=await A.init(),X=i,R=n,t&&console.log("[AgentFramework:init] Initialization complete"),M}function F(){return M}function de(){return A!==null}function ce(){return{initialized:A!==null,source:X,hasSiteKey:!!R?.siteKey}}function D(){M&&M.destroy(),A=null,M=null,X=null,R=null}function U(o){let e={...P,...o};return e.prompt&&e.newChat===void 0&&(e.newChat=!0),e}async function ge(o={}){let e=U(o),t=new T(e),i=await t.init();return{manager:t,api:i}}var _=class{constructor(e,t="static"){this.config=e;this.source=t;d(this,"name","static")}getConfig(){return{config:this.config,source:this.source}}};var C=class{constructor(){d(this,"name","data-attributes")}getConfig(e){let t=e.scriptElement;if(!t||t.hasAttribute("data-defer-init")||t.hasAttribute("data-no-auto-init"))return null;let i=j(t);return Array.from(t.attributes).some(r=>r.name.startsWith("data-")&&r.name!=="data-defer-init"&&r.name!=="data-no-auto-init")?{config:i,source:"data-attributes",metadata:{scriptSrc:t.src}}:null}};function j(o){let e={},t=o.getAttribute("data-container");t&&(e.container=t);let i=o.getAttribute("data-mode");i&&(e.mode=i);let n=o.getAttribute("data-position");n&&(e.position=n);let r=o.getAttribute("data-theme");r&&(e.theme=r);let s=o.getAttribute("data-width");s&&(e.width=s);let l=o.getAttribute("data-height");l&&(e.height=l);let a=o.getAttribute("data-side-width");a&&(e.sideWidth=a);let c=o.getAttribute("data-side-min-width");c&&(e.sideMinWidth=parseInt(c,10));let f=o.getAttribute("data-side-max-width");f&&(e.sideMaxWidth=parseInt(f,10));let y=o.getAttribute("data-side-strategy");y&&(e.sideStrategy=y),o.hasAttribute("data-start-open")&&(e.startOpen=!0),o.hasAttribute("data-no-launcher")&&(e.showLauncher=!1),o.hasAttribute("data-debug")&&(e.debug=!0),o.hasAttribute("data-no-drag")&&(e.draggable=!1),o.hasAttribute("data-no-persist")&&(e.persistPosition=!1),o.hasAttribute("data-enable-dom")&&(e.enableDOM=!0),o.hasAttribute("data-disable-mcp")&&(e.enableMCP=!1),o.hasAttribute("data-enable-tool-discovery")&&(e.enableToolDiscovery=!0);let h=o.getAttribute("data-tool-discovery-url");h&&(e.toolDiscoveryUrl=h);let g=o.getAttribute("data-iframe-url");g&&(e.iframeUrl=g);let m=o.getAttribute("data-site-key");m&&(e.siteKey=m),o.hasAttribute("data-new-chat")&&(e.newChat=!0);let v=o.getAttribute("data-prompt");v&&(e.prompt=v,e.newChat||(e.newChat=!0));let u=o.getAttribute("data-initial-x");u&&(e.initialX=parseInt(u,10));let b=o.getAttribute("data-initial-y");b&&(e.initialY=parseInt(b,10));let w=o.getAttribute("data-z-index");w&&(e.zIndex=parseInt(w,10));let k=o.getAttribute("data-title");k&&(e.title=k);let H=o.getAttribute("data-header-background");H&&(e.headerBackground=H);let B=o.getAttribute("data-header-text-color");B&&(e.headerTextColor=B);let Y=o.getAttribute("data-header-accent-color");Y&&(e.headerAccentColor=Y),o.hasAttribute("data-enable-auto-run")&&(e.enableAutoRun=!0);let V=o.getAttribute("data-auto-run-timing");return V&&(e.autoRunTiming=V),e}async function Pe(o={}){return L(o,{source:"init-legacy"})}function Ae(){return F()}function Le(){D()}function De(){if(document.currentScript)return document.currentScript;let o=document.querySelectorAll('script[src*="embed.js"]');return o.length>0?o[o.length-1]:null}function He(){if(typeof document>"u")return;let o=De();if(!o)return;let t=new C().getConfig({url:window.location.href,scriptElement:o});if(!t)return;let i=()=>{L(t.config,{source:"data-attributes",debug:t.config.debug})};document.readyState==="loading"?document.addEventListener("DOMContentLoaded",i):i()}He();typeof window<"u"&&(window.AgentFramework={init:L,getAPI:F,destroy:D,providers:{DataAttributeConfigProvider:C}});return ye(ze);})();
//# sourceMappingURL=embed.js.map
