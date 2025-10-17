 function fadeOutElement(element, done) {
     element.animate([
         { opacity: 1, transform: 'scale(1)' },
         { opacity: 0, transform: 'scale(0.8)' }
     ], {
         duration: 300,
         easing: 'ease-out'
     }).onfinish = () => {
         done();
     };
 }

 function sendMessage(name, payload) {
     try {
         window.webkit.messageHandlers[name].postMessage(payload);
     } catch (_) {

     }
 }

 function descriptorForEnclosingElement(element) {
     if (!element) {
         return null;
     }

     // Scenario: Parent has a "similar" size
     let targetElement = element;
     while (targetElement.parentElement &&
         targetElement.parentElement !== document.body &&
         targetElement.parentElement !== document.documentElement) {

         const childRect = targetElement.getBoundingClientRect();
         const parentRect = targetElement.parentElement.getBoundingClientRect();

         // Check if parent has the same dimensions (with small tolerance)
         const tolerance = 10;
         if (Math.abs(childRect.width - parentRect.width) < tolerance &&
             Math.abs(childRect.height - parentRect.height) < tolerance) {
             // Parent has an acceptable size
             targetElement = targetElement.parentElement;
         } else {
             // Parent has different size, stop here
             break;
         }
     }

     return descriptorForElement(targetElement);
 }

 function descriptorForElement(element) {
     const r = element.getBoundingClientRect();

     return {
         frame: [[r.left, r.top], [r.width, r.height]],
         xpath: xpathForElement(element)
     };
 }

 function xpathForElement(element) {
     if (element.id !== '') {
         return `//*[@id="${element.id}"]`;
     }

     if (element === document.body) {
         return '/html/body';
     }

     let path = [];
     while (element && element.nodeType === Node.ELEMENT_NODE) {
         let index = 1;
         let sibling = element.previousSibling;

         while (sibling) {
             if (sibling.nodeType === Node.ELEMENT_NODE &&
                 sibling.nodeName === element.nodeName) {
                 index++;
             }
             sibling = sibling.previousSibling;
         }

         const tagName = element.nodeName.toLowerCase();
         const pathIndex = `[${index}]`;
         path.unshift(tagName + pathIndex);

         element = element.parentNode;
     }

     return '/' + path.join('/');
 }

 function elementForXPath(xpath) {
     const result = document.evaluate(
         xpath,                                  // XPath string
         document,                               // Context node
         null,                                   // Namespace resolver
         XPathResult.FIRST_ORDERED_NODE_TYPE,    // Return type
         null                                    // Result to reuse
     );
     return result.singleNodeValue;
 }

 // Public API(s)

 function dismissAndRemoveElementForXPath(message) {
     try {
         const xpath = message.params;
         const element = elementForXPath(xpath);
         if (!element) {
             return;
         }

         fadeOutElement(element, () => {
             if (element.isConnected) {
                 element.remove();
             }

             const descriptor = descriptorForElement(element);
             sendMessage('dismissHighlight', descriptor);
         });
     } catch (exception) {

     }
 }

 function descriptorForElementAtLocation(message) {
     const location = message.params;
     const element = document.elementFromPoint(location.x, location.y);
     if (!element || element === document.documentElement || element === document.body) {
         return null;
     }

     const descriptor = descriptorForEnclosingElement(element);
     if (!descriptor) {
         sendMessage('dismissHighlight', {});
         return;
     }

     sendMessage('displayHighlight', descriptor);
 }

 window.descriptorForElementAtLocation = descriptorForElementAtLocation;
 window.dismissAndRemoveElementForXPath = dismissAndRemoveElementForXPath;

 window.addEventListener('scroll', () => sendMessage('dismissHighlight', {}), { passive: true });
 window.addEventListener('resize', () => sendMessage('dismissHighlight', {}), { passive: true });
