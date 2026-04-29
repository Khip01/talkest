// Compiles a dart2wasm-generated main module from `source` which can then
// instantiatable via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(
      await WebAssembly.compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm modules from `bytes` which is then
// instantiatable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export async function instantiate(modulePromise, importObjectPromise) {
  var moduleOrCompiledApp = await modulePromise;
  if (!(moduleOrCompiledApp instanceof CompiledApp)) {
    moduleOrCompiledApp = new CompiledApp(moduleOrCompiledApp);
  }
  const instantiatedApp = await moduleOrCompiledApp.instantiate(await importObjectPromise);
  return instantiatedApp.instantiatedModule;
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export const invoke = (moduleInstance, ...args) => {
  moduleInstance.exports.$invokeMain(args);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredWasm` is a JS function that takes a module name matching a
  //   wasm file produced by the dart2wasm compiler and returns the bytes to
  //   load the module. These bytes can be in either a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`.
  // `loadDynamicModule` is a JS function that takes two string names matching,
  //   in order, a wasm file produced by the dart2wasm compiler during dynamic
  //   module compilation and a corresponding js file produced by the same
  //   compilation. It should return a JS Array containing 2 elements. The first
  //   should be the bytes for the wasm module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The second
  //   should be the result of using the JS 'import' API on the js file path.
  async instantiate(additionalImports, {loadDeferredWasm, loadDynamicModule} = {}) {
    let dartInstance;

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + value;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {
            _4: (o, c) => o instanceof c,
      _5: o => Object.keys(o),
      _36: x0 => new Array(x0),
      _38: x0 => x0.length,
      _40: (x0,x1) => x0[x1],
      _41: (x0,x1,x2) => { x0[x1] = x2 },
      _43: x0 => new Promise(x0),
      _45: (x0,x1,x2) => new DataView(x0,x1,x2),
      _47: x0 => new Int8Array(x0),
      _48: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      _49: x0 => new Uint8Array(x0),
      _51: x0 => new Uint8ClampedArray(x0),
      _53: x0 => new Int16Array(x0),
      _55: x0 => new Uint16Array(x0),
      _57: x0 => new Int32Array(x0),
      _59: x0 => new Uint32Array(x0),
      _61: x0 => new Float32Array(x0),
      _63: x0 => new Float64Array(x0),
      _65: (x0,x1,x2) => x0.call(x1,x2),
      _67: (x0,x1) => x0.call(x1),
      _70: (decoder, codeUnits) => decoder.decode(codeUnits),
      _71: () => new TextDecoder("utf-8", {fatal: true}),
      _72: () => new TextDecoder("utf-8", {fatal: false}),
      _73: (s) => +s,
      _74: x0 => new Uint8Array(x0),
      _75: (x0,x1,x2) => x0.set(x1,x2),
      _76: (x0,x1) => x0.transferFromImageBitmap(x1),
      _78: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._78(f,arguments.length,x0) }),
      _79: x0 => new window.FinalizationRegistry(x0),
      _80: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      _81: (x0,x1) => x0.unregister(x1),
      _82: (x0,x1,x2) => x0.slice(x1,x2),
      _83: (x0,x1) => x0.decode(x1),
      _84: (x0,x1) => x0.segment(x1),
      _85: () => new TextDecoder(),
      _86: (x0,x1) => x0.get(x1),
      _87: x0 => x0.buffer,
      _88: x0 => x0.wasmMemory,
      _89: () => globalThis.window._flutter_skwasmInstance,
      _90: x0 => x0.rasterStartMilliseconds,
      _91: x0 => x0.rasterEndMilliseconds,
      _92: x0 => x0.imageBitmaps,
      _196: x0 => x0.stopPropagation(),
      _197: x0 => x0.preventDefault(),
      _199: x0 => x0.remove(),
      _200: (x0,x1) => x0.append(x1),
      _201: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _246: x0 => x0.unlock(),
      _247: x0 => x0.getReader(),
      _248: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _249: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      _250: (x0,x1) => x0.item(x1),
      _251: x0 => x0.next(),
      _252: x0 => x0.now(),
      _253: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._253(f,arguments.length,x0) }),
      _254: (x0,x1) => x0.addListener(x1),
      _255: (x0,x1) => x0.removeListener(x1),
      _256: (x0,x1) => x0.matchMedia(x1),
      _257: (x0,x1) => x0.revokeObjectURL(x1),
      _258: x0 => x0.close(),
      _259: (x0,x1,x2,x3,x4) => ({type: x0,data: x1,premultiplyAlpha: x2,colorSpaceConversion: x3,preferAnimation: x4}),
      _260: x0 => new window.ImageDecoder(x0),
      _261: x0 => ({frameIndex: x0}),
      _262: (x0,x1) => x0.decode(x1),
      _263: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._263(f,arguments.length,x0) }),
      _264: (x0,x1) => x0.getModifierState(x1),
      _265: (x0,x1) => x0.removeProperty(x1),
      _266: (x0,x1) => x0.prepend(x1),
      _267: x0 => new Intl.Locale(x0),
      _268: x0 => x0.disconnect(),
      _269: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._269(f,arguments.length,x0) }),
      _270: (x0,x1) => x0.getAttribute(x1),
      _271: (x0,x1) => x0.contains(x1),
      _272: (x0,x1) => x0.querySelector(x1),
      _273: x0 => x0.blur(),
      _274: x0 => x0.hasFocus(),
      _275: (x0,x1,x2) => x0.insertBefore(x1,x2),
      _276: (x0,x1) => x0.hasAttribute(x1),
      _277: (x0,x1) => x0.getModifierState(x1),
      _278: (x0,x1) => x0.createTextNode(x1),
      _279: (x0,x1) => x0.appendChild(x1),
      _280: (x0,x1) => x0.removeAttribute(x1),
      _281: x0 => x0.getBoundingClientRect(),
      _282: (x0,x1) => x0.observe(x1),
      _283: x0 => x0.disconnect(),
      _284: (x0,x1) => x0.closest(x1),
      _707: () => globalThis.window.flutterConfiguration,
      _709: x0 => x0.assetBase,
      _714: x0 => x0.canvasKitMaximumSurfaces,
      _715: x0 => x0.debugShowSemanticsNodes,
      _716: x0 => x0.hostElement,
      _717: x0 => x0.multiViewEnabled,
      _718: x0 => x0.nonce,
      _720: x0 => x0.fontFallbackBaseUrl,
      _730: x0 => x0.console,
      _731: x0 => x0.devicePixelRatio,
      _732: x0 => x0.document,
      _733: x0 => x0.history,
      _734: x0 => x0.innerHeight,
      _735: x0 => x0.innerWidth,
      _736: x0 => x0.location,
      _737: x0 => x0.navigator,
      _738: x0 => x0.visualViewport,
      _739: x0 => x0.performance,
      _741: x0 => x0.URL,
      _743: (x0,x1) => x0.getComputedStyle(x1),
      _744: x0 => x0.screen,
      _745: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._745(f,arguments.length,x0) }),
      _746: (x0,x1) => x0.requestAnimationFrame(x1),
      _751: (x0,x1) => x0.warn(x1),
      _753: (x0,x1) => x0.debug(x1),
      _754: x0 => globalThis.parseFloat(x0),
      _755: () => globalThis.window,
      _756: () => globalThis.Intl,
      _757: () => globalThis.Symbol,
      _758: (x0,x1,x2,x3,x4) => globalThis.createImageBitmap(x0,x1,x2,x3,x4),
      _760: x0 => x0.clipboard,
      _761: x0 => x0.maxTouchPoints,
      _762: x0 => x0.vendor,
      _763: x0 => x0.language,
      _764: x0 => x0.platform,
      _765: x0 => x0.userAgent,
      _766: (x0,x1) => x0.vibrate(x1),
      _767: x0 => x0.languages,
      _768: x0 => x0.documentElement,
      _769: (x0,x1) => x0.querySelector(x1),
      _772: (x0,x1) => x0.createElement(x1),
      _775: (x0,x1) => x0.createEvent(x1),
      _776: x0 => x0.activeElement,
      _779: x0 => x0.head,
      _780: x0 => x0.body,
      _782: (x0,x1) => { x0.title = x1 },
      _785: x0 => x0.visibilityState,
      _786: () => globalThis.document,
      _787: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._787(f,arguments.length,x0) }),
      _788: (x0,x1) => x0.dispatchEvent(x1),
      _796: x0 => x0.target,
      _798: x0 => x0.timeStamp,
      _799: x0 => x0.type,
      _801: (x0,x1,x2,x3) => x0.initEvent(x1,x2,x3),
      _808: x0 => x0.firstChild,
      _812: x0 => x0.parentElement,
      _814: (x0,x1) => { x0.textContent = x1 },
      _815: x0 => x0.parentNode,
      _816: x0 => x0.nextSibling,
      _817: (x0,x1) => x0.removeChild(x1),
      _818: x0 => x0.isConnected,
      _826: x0 => x0.clientHeight,
      _827: x0 => x0.clientWidth,
      _828: x0 => x0.offsetHeight,
      _829: x0 => x0.offsetWidth,
      _830: x0 => x0.id,
      _831: (x0,x1) => { x0.id = x1 },
      _834: (x0,x1) => { x0.spellcheck = x1 },
      _835: x0 => x0.tagName,
      _836: x0 => x0.style,
      _838: (x0,x1) => x0.querySelectorAll(x1),
      _839: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _840: (x0,x1) => { x0.tabIndex = x1 },
      _841: x0 => x0.tabIndex,
      _842: (x0,x1) => x0.focus(x1),
      _843: x0 => x0.scrollTop,
      _844: (x0,x1) => { x0.scrollTop = x1 },
      _845: x0 => x0.scrollLeft,
      _846: (x0,x1) => { x0.scrollLeft = x1 },
      _847: x0 => x0.classList,
      _849: (x0,x1) => { x0.className = x1 },
      _851: (x0,x1) => x0.getElementsByClassName(x1),
      _852: x0 => x0.click(),
      _853: (x0,x1) => x0.attachShadow(x1),
      _856: x0 => x0.computedStyleMap(),
      _857: (x0,x1) => x0.get(x1),
      _863: (x0,x1) => x0.getPropertyValue(x1),
      _864: (x0,x1,x2,x3) => x0.setProperty(x1,x2,x3),
      _865: x0 => x0.offsetLeft,
      _866: x0 => x0.offsetTop,
      _867: x0 => x0.offsetParent,
      _869: (x0,x1) => { x0.name = x1 },
      _870: x0 => x0.content,
      _871: (x0,x1) => { x0.content = x1 },
      _875: (x0,x1) => { x0.src = x1 },
      _876: x0 => x0.naturalWidth,
      _877: x0 => x0.naturalHeight,
      _881: (x0,x1) => { x0.crossOrigin = x1 },
      _883: (x0,x1) => { x0.decoding = x1 },
      _884: x0 => x0.decode(),
      _889: (x0,x1) => { x0.nonce = x1 },
      _894: (x0,x1) => { x0.width = x1 },
      _896: (x0,x1) => { x0.height = x1 },
      _899: (x0,x1) => x0.getContext(x1),
      _960: x0 => x0.width,
      _961: x0 => x0.height,
      _963: (x0,x1) => x0.fetch(x1),
      _964: x0 => x0.status,
      _965: x0 => x0.headers,
      _966: x0 => x0.body,
      _967: x0 => x0.arrayBuffer(),
      _970: x0 => x0.read(),
      _971: x0 => x0.value,
      _972: x0 => x0.done,
      _979: x0 => x0.name,
      _980: x0 => x0.x,
      _981: x0 => x0.y,
      _984: x0 => x0.top,
      _985: x0 => x0.right,
      _986: x0 => x0.bottom,
      _987: x0 => x0.left,
      _997: x0 => x0.height,
      _998: x0 => x0.width,
      _999: x0 => x0.scale,
      _1000: (x0,x1) => { x0.value = x1 },
      _1003: (x0,x1) => { x0.placeholder = x1 },
      _1005: (x0,x1) => { x0.name = x1 },
      _1006: x0 => x0.selectionDirection,
      _1007: x0 => x0.selectionStart,
      _1008: x0 => x0.selectionEnd,
      _1011: x0 => x0.value,
      _1013: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _1014: x0 => x0.readText(),
      _1015: (x0,x1) => x0.writeText(x1),
      _1017: x0 => x0.altKey,
      _1018: x0 => x0.code,
      _1019: x0 => x0.ctrlKey,
      _1020: x0 => x0.key,
      _1021: x0 => x0.keyCode,
      _1022: x0 => x0.location,
      _1023: x0 => x0.metaKey,
      _1024: x0 => x0.repeat,
      _1025: x0 => x0.shiftKey,
      _1026: x0 => x0.isComposing,
      _1028: x0 => x0.state,
      _1029: (x0,x1) => x0.go(x1),
      _1031: (x0,x1,x2,x3) => x0.pushState(x1,x2,x3),
      _1032: (x0,x1,x2,x3) => x0.replaceState(x1,x2,x3),
      _1033: x0 => x0.pathname,
      _1034: x0 => x0.search,
      _1035: x0 => x0.hash,
      _1039: x0 => x0.state,
      _1042: (x0,x1) => x0.createObjectURL(x1),
      _1044: x0 => new Blob(x0),
      _1046: x0 => new MutationObserver(x0),
      _1047: (x0,x1,x2) => x0.observe(x1,x2),
      _1048: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1048(f,arguments.length,x0,x1) }),
      _1051: x0 => x0.attributeName,
      _1052: x0 => x0.type,
      _1053: x0 => x0.matches,
      _1054: x0 => x0.matches,
      _1058: x0 => x0.relatedTarget,
      _1060: x0 => x0.clientX,
      _1061: x0 => x0.clientY,
      _1062: x0 => x0.offsetX,
      _1063: x0 => x0.offsetY,
      _1066: x0 => x0.button,
      _1067: x0 => x0.buttons,
      _1068: x0 => x0.ctrlKey,
      _1072: x0 => x0.pointerId,
      _1073: x0 => x0.pointerType,
      _1074: x0 => x0.pressure,
      _1075: x0 => x0.tiltX,
      _1076: x0 => x0.tiltY,
      _1077: x0 => x0.getCoalescedEvents(),
      _1080: x0 => x0.deltaX,
      _1081: x0 => x0.deltaY,
      _1082: x0 => x0.wheelDeltaX,
      _1083: x0 => x0.wheelDeltaY,
      _1084: x0 => x0.deltaMode,
      _1091: x0 => x0.changedTouches,
      _1094: x0 => x0.clientX,
      _1095: x0 => x0.clientY,
      _1098: x0 => x0.data,
      _1101: (x0,x1) => { x0.disabled = x1 },
      _1103: (x0,x1) => { x0.type = x1 },
      _1104: (x0,x1) => { x0.max = x1 },
      _1105: (x0,x1) => { x0.min = x1 },
      _1106: x0 => x0.value,
      _1107: (x0,x1) => { x0.value = x1 },
      _1108: x0 => x0.disabled,
      _1109: (x0,x1) => { x0.disabled = x1 },
      _1111: (x0,x1) => { x0.placeholder = x1 },
      _1112: (x0,x1) => { x0.name = x1 },
      _1115: (x0,x1) => { x0.autocomplete = x1 },
      _1116: x0 => x0.selectionDirection,
      _1117: x0 => x0.selectionStart,
      _1119: x0 => x0.selectionEnd,
      _1122: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _1123: (x0,x1) => x0.add(x1),
      _1126: (x0,x1) => { x0.noValidate = x1 },
      _1127: (x0,x1) => { x0.method = x1 },
      _1128: (x0,x1) => { x0.action = x1 },
      _1154: x0 => x0.orientation,
      _1155: x0 => x0.width,
      _1156: x0 => x0.height,
      _1157: (x0,x1) => x0.lock(x1),
      _1176: x0 => new ResizeObserver(x0),
      _1179: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1179(f,arguments.length,x0,x1) }),
      _1187: x0 => x0.length,
      _1188: x0 => x0.iterator,
      _1189: x0 => x0.Segmenter,
      _1190: x0 => x0.v8BreakIterator,
      _1191: (x0,x1) => new Intl.Segmenter(x0,x1),
      _1194: x0 => x0.language,
      _1195: x0 => x0.script,
      _1196: x0 => x0.region,
      _1214: x0 => x0.done,
      _1215: x0 => x0.value,
      _1216: x0 => x0.index,
      _1220: (x0,x1) => new Intl.v8BreakIterator(x0,x1),
      _1221: (x0,x1) => x0.adoptText(x1),
      _1222: x0 => x0.first(),
      _1223: x0 => x0.next(),
      _1224: x0 => x0.current(),
      _1238: x0 => x0.hostElement,
      _1239: x0 => x0.viewConstraints,
      _1242: x0 => x0.maxHeight,
      _1243: x0 => x0.maxWidth,
      _1244: x0 => x0.minHeight,
      _1245: x0 => x0.minWidth,
      _1246: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1246(f,arguments.length,x0) }),
      _1247: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1247(f,arguments.length,x0) }),
      _1248: (x0,x1) => ({addView: x0,removeView: x1}),
      _1251: x0 => x0.loader,
      _1252: () => globalThis._flutter,
      _1253: (x0,x1) => x0.didCreateEngineInitializer(x1),
      _1254: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1254(f,arguments.length,x0) }),
      _1255: f => finalizeWrapper(f, function() { return dartInstance.exports._1255(f,arguments.length) }),
      _1256: (x0,x1) => ({initializeEngine: x0,autoStart: x1}),
      _1259: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1259(f,arguments.length,x0) }),
      _1260: x0 => ({runApp: x0}),
      _1262: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1262(f,arguments.length,x0,x1) }),
      _1263: x0 => x0.length,
      _1264: () => globalThis.window.ImageDecoder,
      _1265: x0 => x0.tracks,
      _1267: x0 => x0.completed,
      _1269: x0 => x0.image,
      _1275: x0 => x0.displayWidth,
      _1276: x0 => x0.displayHeight,
      _1277: x0 => x0.duration,
      _1280: x0 => x0.ready,
      _1281: x0 => x0.selectedTrack,
      _1282: x0 => x0.repetitionCount,
      _1283: x0 => x0.frameCount,
      _1331: (x0,x1) => x0.createElement(x1),
      _1337: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _1338: () => globalThis.window.navigator.userAgent,
      _1342: (x0,x1) => x0.createElement(x1),
      _1343: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _1345: (x0,x1) => x0.getAttribute(x1),
      _1349: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1357: x0 => x0.toArray(),
      _1358: x0 => x0.toUint8Array(),
      _1359: x0 => ({serverTimestamps: x0}),
      _1360: x0 => ({source: x0}),
      _1361: x0 => ({merge: x0}),
      _1363: x0 => new firebase_firestore.FieldPath(x0),
      _1364: (x0,x1) => new firebase_firestore.FieldPath(x0,x1),
      _1365: (x0,x1,x2) => new firebase_firestore.FieldPath(x0,x1,x2),
      _1366: (x0,x1,x2,x3) => new firebase_firestore.FieldPath(x0,x1,x2,x3),
      _1367: (x0,x1,x2,x3,x4) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4),
      _1368: (x0,x1,x2,x3,x4,x5) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5),
      _1369: (x0,x1,x2,x3,x4,x5,x6) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6),
      _1370: (x0,x1,x2,x3,x4,x5,x6,x7) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6,x7),
      _1371: (x0,x1,x2,x3,x4,x5,x6,x7,x8) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6,x7,x8),
      _1372: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6,x7,x8,x9),
      _1373: () => globalThis.firebase_firestore.documentId(),
      _1374: (x0,x1) => new firebase_firestore.GeoPoint(x0,x1),
      _1375: x0 => globalThis.firebase_firestore.vector(x0),
      _1376: x0 => globalThis.firebase_firestore.Bytes.fromUint8Array(x0),
      _1377: x0 => globalThis.firebase_firestore.writeBatch(x0),
      _1378: (x0,x1) => globalThis.firebase_firestore.collection(x0,x1),
      _1380: (x0,x1) => globalThis.firebase_firestore.doc(x0,x1),
      _1383: x0 => x0.call(),
      _1407: x0 => x0.commit(),
      _1410: (x0,x1,x2) => x0.set(x1,x2),
      _1411: (x0,x1,x2) => x0.update(x1,x2),
      _1413: x0 => globalThis.firebase_firestore.getDoc(x0),
      _1414: x0 => globalThis.firebase_firestore.getDocFromServer(x0),
      _1415: x0 => globalThis.firebase_firestore.getDocFromCache(x0),
      _1416: (x0,x1) => ({includeMetadataChanges: x0,source: x1}),
      _1419: (x0,x1,x2,x3) => globalThis.firebase_firestore.onSnapshot(x0,x1,x2,x3),
      _1421: (x0,x1,x2) => globalThis.firebase_firestore.setDoc(x0,x1,x2),
      _1422: (x0,x1) => globalThis.firebase_firestore.setDoc(x0,x1),
      _1423: (x0,x1) => globalThis.firebase_firestore.query(x0,x1),
      _1424: x0 => globalThis.firebase_firestore.getDocs(x0),
      _1425: x0 => globalThis.firebase_firestore.getDocsFromServer(x0),
      _1426: x0 => globalThis.firebase_firestore.getDocsFromCache(x0),
      _1427: x0 => globalThis.firebase_firestore.limit(x0),
      _1428: x0 => globalThis.firebase_firestore.limitToLast(x0),
      _1429: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1429(f,arguments.length,x0) }),
      _1430: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1430(f,arguments.length,x0) }),
      _1431: (x0,x1) => globalThis.firebase_firestore.orderBy(x0,x1),
      _1433: (x0,x1,x2) => globalThis.firebase_firestore.where(x0,x1,x2),
      _1435: x0 => globalThis.firebase_firestore.doc(x0),
      _1438: (x0,x1) => x0.data(x1),
      _1442: x0 => x0.docChanges(),
      _1452: x0 => globalThis.firebase_firestore.increment(x0),
      _1459: (x0,x1) => globalThis.firebase_firestore.getFirestore(x0,x1),
      _1461: x0 => globalThis.firebase_firestore.Timestamp.fromMillis(x0),
      _1462: f => finalizeWrapper(f, function() { return dartInstance.exports._1462(f,arguments.length) }),
      _1479: () => globalThis.firebase_firestore.updateDoc,
      _1480: () => globalThis.firebase_firestore.or,
      _1481: () => globalThis.firebase_firestore.and,
      _1486: x0 => x0.path,
      _1489: () => globalThis.firebase_firestore.GeoPoint,
      _1490: x0 => x0.latitude,
      _1491: x0 => x0.longitude,
      _1493: () => globalThis.firebase_firestore.VectorValue,
      _1494: () => globalThis.firebase_firestore.Bytes,
      _1497: x0 => x0.type,
      _1499: x0 => x0.doc,
      _1501: x0 => x0.oldIndex,
      _1503: x0 => x0.newIndex,
      _1505: () => globalThis.firebase_firestore.DocumentReference,
      _1509: x0 => x0.path,
      _1518: x0 => x0.metadata,
      _1519: x0 => x0.ref,
      _1524: x0 => x0.docs,
      _1526: x0 => x0.metadata,
      _1530: () => globalThis.firebase_firestore.Timestamp,
      _1531: x0 => x0.seconds,
      _1532: x0 => x0.nanoseconds,
      _1568: x0 => x0.hasPendingWrites,
      _1570: x0 => x0.fromCache,
      _1577: x0 => x0.source,
      _1582: () => globalThis.firebase_firestore.startAfter,
      _1583: () => globalThis.firebase_firestore.startAt,
      _1584: () => globalThis.firebase_firestore.endBefore,
      _1585: () => globalThis.firebase_firestore.endAt,
      _1598: (x0,x1) => x0.item(x1),
      _1599: (x0,x1) => x0.querySelector(x1),
      _1600: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1600(f,arguments.length,x0) }),
      _1601: (x0,x1) => x0.removeChild(x1),
      _1602: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1602(f,arguments.length,x0) }),
      _1603: (x0,x1) => x0.appendChild(x1),
      _1604: () => new Map(),
      _1605: (x0,x1,x2) => x0.set(x1,x2),
      _1606: (x0,x1,x2,x3) => x0.call(x1,x2,x3),
      _1607: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1607(f,arguments.length,x0,x1) }),
      _1608: (x0,x1) => new ZXing.BrowserMultiFormatReader(x0,x1),
      _1609: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1609(f,arguments.length,x0) }),
      _1610: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1610(f,arguments.length,x0) }),
      _1611: (x0,x1) => x0.append(x1),
      _1612: x0 => x0.getVideoTracks(),
      _1613: x0 => x0.getCapabilities(),
      _1614: () => ({}),
      _1615: x0 => x0.getSettings(),
      _1616: x0 => x0.getSupportedConstraints(),
      _1617: x0 => ({video: x0}),
      _1618: x0 => ({facingMode: x0}),
      _1619: (x0,x1) => x0.getUserMedia(x1),
      _1620: x0 => x0.decode(),
      _1621: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1622: (x0,x1,x2) => x0.setRequestHeader(x1,x2),
      _1623: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1623(f,arguments.length,x0) }),
      _1624: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1624(f,arguments.length,x0) }),
      _1625: x0 => x0.send(),
      _1626: () => new XMLHttpRequest(),
      _1628: (x0,x1) => x0.getIdToken(x1),
      _1647: x0 => x0.toJSON(),
      _1648: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1648(f,arguments.length,x0) }),
      _1649: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1649(f,arguments.length,x0) }),
      _1650: (x0,x1,x2) => x0.onAuthStateChanged(x1,x2),
      _1651: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1651(f,arguments.length,x0) }),
      _1652: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1652(f,arguments.length,x0) }),
      _1653: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1653(f,arguments.length,x0) }),
      _1654: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1654(f,arguments.length,x0) }),
      _1655: (x0,x1,x2) => x0.onIdTokenChanged(x1,x2),
      _1672: (x0,x1) => globalThis.firebase_auth.signInWithPopup(x0,x1),
      _1674: x0 => x0.signOut(),
      _1675: (x0,x1) => globalThis.firebase_auth.connectAuthEmulator(x0,x1),
      _1690: () => new firebase_auth.GoogleAuthProvider(),
      _1691: (x0,x1) => x0.addScope(x1),
      _1692: (x0,x1) => x0.setCustomParameters(x1),
      _1698: x0 => globalThis.firebase_auth.OAuthProvider.credentialFromResult(x0),
      _1713: x0 => globalThis.firebase_auth.getAdditionalUserInfo(x0),
      _1714: (x0,x1,x2) => ({errorMap: x0,persistence: x1,popupRedirectResolver: x2}),
      _1715: (x0,x1) => globalThis.firebase_auth.initializeAuth(x0,x1),
      _1721: x0 => globalThis.firebase_auth.OAuthProvider.credentialFromError(x0),
      _1736: () => globalThis.firebase_auth.debugErrorMap,
      _1739: () => globalThis.firebase_auth.browserSessionPersistence,
      _1741: () => globalThis.firebase_auth.browserLocalPersistence,
      _1743: () => globalThis.firebase_auth.indexedDBLocalPersistence,
      _1746: x0 => globalThis.firebase_auth.multiFactor(x0),
      _1747: (x0,x1) => globalThis.firebase_auth.getMultiFactorResolver(x0,x1),
      _1749: x0 => x0.currentUser,
      _1753: x0 => x0.tenantId,
      _1763: x0 => x0.displayName,
      _1764: x0 => x0.email,
      _1765: x0 => x0.phoneNumber,
      _1766: x0 => x0.photoURL,
      _1767: x0 => x0.providerId,
      _1768: x0 => x0.uid,
      _1769: x0 => x0.emailVerified,
      _1770: x0 => x0.isAnonymous,
      _1771: x0 => x0.providerData,
      _1772: x0 => x0.refreshToken,
      _1773: x0 => x0.tenantId,
      _1774: x0 => x0.metadata,
      _1776: x0 => x0.providerId,
      _1777: x0 => x0.signInMethod,
      _1778: x0 => x0.accessToken,
      _1779: x0 => x0.idToken,
      _1780: x0 => x0.secret,
      _1791: x0 => x0.creationTime,
      _1792: x0 => x0.lastSignInTime,
      _1797: x0 => x0.code,
      _1799: x0 => x0.message,
      _1811: x0 => x0.email,
      _1812: x0 => x0.phoneNumber,
      _1813: x0 => x0.tenantId,
      _1836: x0 => x0.user,
      _1839: x0 => x0.providerId,
      _1840: x0 => x0.profile,
      _1841: x0 => x0.username,
      _1842: x0 => x0.isNewUser,
      _1845: () => globalThis.firebase_auth.browserPopupRedirectResolver,
      _1850: x0 => x0.displayName,
      _1851: x0 => x0.enrollmentTime,
      _1852: x0 => x0.factorId,
      _1853: x0 => x0.uid,
      _1855: x0 => x0.hints,
      _1856: x0 => x0.session,
      _1858: x0 => x0.phoneNumber,
      _1870: (x0,x1) => x0.getItem(x1),
      _1878: (x0,x1,x2) => x0.setItem(x1,x2),
      _1880: (x0,x1,x2,x3,x4,x5,x6,x7) => ({apiKey: x0,authDomain: x1,databaseURL: x2,projectId: x3,storageBucket: x4,messagingSenderId: x5,measurementId: x6,appId: x7}),
      _1881: (x0,x1) => globalThis.firebase_core.initializeApp(x0,x1),
      _1882: x0 => globalThis.firebase_core.getApp(x0),
      _1883: () => globalThis.firebase_core.getApp(),
      _1884: (x0,x1,x2) => globalThis.firebase_core.registerVersion(x0,x1,x2),
      _1910: () => globalThis.firebase_core.SDK_VERSION,
      _1916: x0 => x0.apiKey,
      _1918: x0 => x0.authDomain,
      _1920: x0 => x0.databaseURL,
      _1922: x0 => x0.projectId,
      _1924: x0 => x0.storageBucket,
      _1926: x0 => x0.messagingSenderId,
      _1928: x0 => x0.measurementId,
      _1930: x0 => x0.appId,
      _1932: x0 => x0.name,
      _1933: x0 => x0.options,
      _1934: (x0,x1) => x0.debug(x1),
      _1935: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1935(f,arguments.length,x0) }),
      _1936: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1936(f,arguments.length,x0,x1) }),
      _1937: (x0,x1) => ({createScript: x0,createScriptURL: x1}),
      _1938: (x0,x1,x2) => x0.createPolicy(x1,x2),
      _1939: (x0,x1) => x0.createScriptURL(x1),
      _1940: (x0,x1,x2) => x0.createScript(x1,x2),
      _1941: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1941(f,arguments.length,x0) }),
      _1942: () => globalThis.removeSplashFromWeb(),
      _1950: x0 => x0.barcodeFormat,
      _1951: x0 => x0.text,
      _1952: x0 => x0.rawBytes,
      _1953: x0 => x0.resultPoints,
      _1955: Date.now,
      _1957: s => new Date(s * 1000).getTimezoneOffset() * 60,
      _1958: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      _1959: () => {
        let stackString = new Error().stack.toString();
        let frames = stackString.split('\n');
        let drop = 2;
        if (frames[0] === 'Error') {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      _1960: () => typeof dartUseDateNowForTicks !== "undefined",
      _1961: () => 1000 * performance.now(),
      _1962: () => Date.now(),
      _1963: () => {
        // On browsers return `globalThis.location.href`
        if (globalThis.location != null) {
          return globalThis.location.href;
        }
        return null;
      },
      _1964: () => {
        return typeof process != "undefined" &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
      _1965: () => new WeakMap(),
      _1966: (map, o) => map.get(o),
      _1967: (map, o, v) => map.set(o, v),
      _1968: x0 => new WeakRef(x0),
      _1969: x0 => x0.deref(),
      _1976: () => globalThis.WeakRef,
      _1979: s => JSON.stringify(s),
      _1980: s => printToConsole(s),
      _1981: (o, p, r) => o.replaceAll(p, () => r),
      _1982: (o, p, r) => o.replace(p, () => r),
      _1983: Function.prototype.call.bind(String.prototype.toLowerCase),
      _1984: s => s.toUpperCase(),
      _1985: s => s.trim(),
      _1986: s => s.trimLeft(),
      _1987: s => s.trimRight(),
      _1988: (string, times) => string.repeat(times),
      _1989: Function.prototype.call.bind(String.prototype.indexOf),
      _1990: (s, p, i) => s.lastIndexOf(p, i),
      _1991: (string, token) => string.split(token),
      _1992: Object.is,
      _1993: o => o instanceof Array,
      _1994: (a, i) => a.push(i),
      _1995: (a, i) => a.splice(i, 1)[0],
      _1997: (a, l) => a.length = l,
      _1998: a => a.pop(),
      _1999: (a, i) => a.splice(i, 1),
      _2000: (a, s) => a.join(s),
      _2001: (a, s, e) => a.slice(s, e),
      _2002: (a, s, e) => a.splice(s, e),
      _2003: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
      _2004: a => a.length,
      _2006: (a, i) => a[i],
      _2007: (a, i, v) => a[i] = v,
      _2009: o => {
        if (o instanceof ArrayBuffer) return 0;
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
          return 1;
        }
        return 2;
      },
      _2010: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      _2012: o => o instanceof Uint8Array,
      _2013: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      _2014: o => o instanceof Int8Array,
      _2015: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      _2016: o => o instanceof Uint8ClampedArray,
      _2017: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      _2018: o => o instanceof Uint16Array,
      _2019: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      _2020: o => o instanceof Int16Array,
      _2021: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      _2022: o => o instanceof Uint32Array,
      _2023: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      _2024: o => o instanceof Int32Array,
      _2025: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      _2027: (o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length),
      _2028: o => o instanceof Float32Array,
      _2029: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      _2030: o => o instanceof Float64Array,
      _2031: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      _2032: (t, s) => t.set(s),
      _2033: l => new DataView(new ArrayBuffer(l)),
      _2034: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      _2036: o => o.buffer,
      _2037: o => o.byteOffset,
      _2038: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      _2039: (b, o) => new DataView(b, o),
      _2040: (b, o, l) => new DataView(b, o, l),
      _2041: Function.prototype.call.bind(DataView.prototype.getUint8),
      _2042: Function.prototype.call.bind(DataView.prototype.setUint8),
      _2043: Function.prototype.call.bind(DataView.prototype.getInt8),
      _2044: Function.prototype.call.bind(DataView.prototype.setInt8),
      _2045: Function.prototype.call.bind(DataView.prototype.getUint16),
      _2046: Function.prototype.call.bind(DataView.prototype.setUint16),
      _2047: Function.prototype.call.bind(DataView.prototype.getInt16),
      _2048: Function.prototype.call.bind(DataView.prototype.setInt16),
      _2049: Function.prototype.call.bind(DataView.prototype.getUint32),
      _2050: Function.prototype.call.bind(DataView.prototype.setUint32),
      _2051: Function.prototype.call.bind(DataView.prototype.getInt32),
      _2052: Function.prototype.call.bind(DataView.prototype.setInt32),
      _2055: Function.prototype.call.bind(DataView.prototype.getBigInt64),
      _2056: Function.prototype.call.bind(DataView.prototype.setBigInt64),
      _2057: Function.prototype.call.bind(DataView.prototype.getFloat32),
      _2058: Function.prototype.call.bind(DataView.prototype.setFloat32),
      _2059: Function.prototype.call.bind(DataView.prototype.getFloat64),
      _2060: Function.prototype.call.bind(DataView.prototype.setFloat64),
      _2073: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      _2074: (handle) => clearTimeout(handle),
      _2075: (ms, c) =>
      setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
      _2076: (handle) => clearInterval(handle),
      _2077: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _2078: () => Date.now(),
      _2079: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      _2080: (x0,x1) => x0.exec(x1),
      _2081: (x0,x1) => x0.test(x1),
      _2082: x0 => x0.pop(),
      _2084: o => o === undefined,
      _2086: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _2088: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      _2089: o => o instanceof RegExp,
      _2090: (l, r) => l === r,
      _2091: o => o,
      _2092: o => o,
      _2093: o => o,
      _2094: b => !!b,
      _2095: o => o.length,
      _2097: (o, i) => o[i],
      _2098: f => f.dartFunction,
      _2099: () => ({}),
      _2100: () => [],
      _2102: () => globalThis,
      _2103: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      _2104: (o, p) => p in o,
      _2105: (o, p) => o[p],
      _2106: (o, p, v) => o[p] = v,
      _2107: (o, m, a) => o[m].apply(o, a),
      _2109: o => String(o),
      _2110: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      _2111: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._2111(f,arguments.length,x0) }),
      _2112: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._2112(f,arguments.length,x0,x1) }),
      _2113: o => {
        if (o === undefined) return 1;
        var type = typeof o;
        if (type === 'boolean') return 2;
        if (type === 'number') return 3;
        if (type === 'string') return 4;
        if (o instanceof Array) return 5;
        if (ArrayBuffer.isView(o)) {
          if (o instanceof Int8Array) return 6;
          if (o instanceof Uint8Array) return 7;
          if (o instanceof Uint8ClampedArray) return 8;
          if (o instanceof Int16Array) return 9;
          if (o instanceof Uint16Array) return 10;
          if (o instanceof Int32Array) return 11;
          if (o instanceof Uint32Array) return 12;
          if (o instanceof Float32Array) return 13;
          if (o instanceof Float64Array) return 14;
          if (o instanceof DataView) return 15;
        }
        if (o instanceof ArrayBuffer) return 16;
        // Feature check for `SharedArrayBuffer` before doing a type-check.
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
            return 17;
        }
        if (o instanceof Promise) return 18;
        return 19;
      },
      _2114: o => [o],
      _2115: (o0, o1) => [o0, o1],
      _2116: (o0, o1, o2) => [o0, o1, o2],
      _2117: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      _2118: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2119: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2120: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI16ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2121: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI16ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2122: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2123: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2124: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2125: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2126: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2127: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF64ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2128: x0 => new ArrayBuffer(x0),
      _2129: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      _2130: x0 => x0.input,
      _2131: x0 => x0.index,
      _2132: x0 => x0.groups,
      _2133: x0 => x0.flags,
      _2134: x0 => x0.multiline,
      _2135: x0 => x0.ignoreCase,
      _2136: x0 => x0.unicode,
      _2137: x0 => x0.dotAll,
      _2138: (x0,x1) => { x0.lastIndex = x1 },
      _2139: (o, p) => p in o,
      _2140: (o, p) => o[p],
      _2141: (o, p, v) => o[p] = v,
      _2142: (o, p) => delete o[p],
      _2156: x0 => x0.trustedTypes,
      _2157: (x0,x1) => { x0.src = x1 },
      _2158: (x0,x1) => x0.createScriptURL(x1),
      _2159: x0 => x0.nonce,
      _2160: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._2160(f,arguments.length,x0) }),
      _2161: x0 => ({createScriptURL: x0}),
      _2162: (x0,x1) => x0.querySelectorAll(x1),
      _2163: () => new AbortController(),
      _2164: x0 => x0.abort(),
      _2165: (x0,x1,x2,x3,x4,x5) => ({method: x0,headers: x1,body: x2,credentials: x3,redirect: x4,signal: x5}),
      _2166: (x0,x1) => globalThis.fetch(x0,x1),
      _2167: (x0,x1) => x0.get(x1),
      _2168: f => finalizeWrapper(f, function(x0,x1,x2) { return dartInstance.exports._2168(f,arguments.length,x0,x1,x2) }),
      _2169: (x0,x1) => x0.forEach(x1),
      _2170: x0 => x0.getReader(),
      _2171: x0 => x0.cancel(),
      _2172: x0 => x0.read(),
      _2173: x0 => x0.attachStreamToVideo,
      _2175: x0 => x0.decodeContinuously,
      _2179: x0 => x0.reset,
      _2181: x0 => x0.stopContinuousDecode,
      _2183: x0 => x0.stream,
      _2184: x0 => x0.videoElement,
      _2185: (x0,x1) => ({width: x0,height: x1}),
      _2186: (x0,x1,x2) => ({width: x0,height: x1,facingMode: x2}),
      _2187: (x0,x1) => x0.key(x1),
      _2188: x0 => x0.getCapabilities,
      _2189: x0 => x0.facingMode,
      _2190: x0 => x0.trustedTypes,
      _2191: (x0,x1) => { x0.text = x1 },
      _2192: x0 => x0.random(),
      _2193: (x0,x1) => x0.getRandomValues(x1),
      _2194: () => globalThis.crypto,
      _2195: () => globalThis.Math,
      _2205: Function.prototype.call.bind(Number.prototype.toString),
      _2206: Function.prototype.call.bind(BigInt.prototype.toString),
      _2207: Function.prototype.call.bind(Number.prototype.toString),
      _2208: (d, digits) => d.toFixed(digits),
      _2212: () => globalThis.document,
      _2218: (x0,x1) => { x0.height = x1 },
      _2220: (x0,x1) => { x0.width = x1 },
      _2229: x0 => x0.style,
      _2232: x0 => x0.src,
      _2233: (x0,x1) => { x0.src = x1 },
      _2234: x0 => x0.naturalWidth,
      _2235: x0 => x0.naturalHeight,
      _2251: x0 => x0.status,
      _2252: (x0,x1) => { x0.responseType = x1 },
      _2254: x0 => x0.response,
      _2255: x0 => x0.x,
      _2256: x0 => x0.y,
      _2333: x0 => { globalThis.onGoogleLibraryLoad = x0 },
      _2334: f => finalizeWrapper(f, function() { return dartInstance.exports._2334(f,arguments.length) }),
      _2432: (x0,x1) => { x0.lang = x1 },
      _2461: x0 => x0.style,
      _2520: (x0,x1) => { x0.onerror = x1 },
      _2536: (x0,x1) => { x0.onload = x1 },
      _2560: (x0,x1) => { x0.onpause = x1 },
      _2562: (x0,x1) => { x0.onplay = x1 },
      _2660: (x0,x1) => { x0.nonce = x1 },
      _3033: x0 => x0.videoWidth,
      _3034: x0 => x0.videoHeight,
      _3099: (x0,x1) => { x0.controls = x1 },
      _3698: (x0,x1) => { x0.src = x1 },
      _3700: (x0,x1) => { x0.type = x1 },
      _3704: (x0,x1) => { x0.async = x1 },
      _3706: (x0,x1) => { x0.defer = x1 },
      _3708: (x0,x1) => { x0.crossOrigin = x1 },
      _3710: (x0,x1) => { x0.text = x1 },
      _4167: () => globalThis.window,
      _4207: x0 => x0.document,
      _4210: x0 => x0.location,
      _4229: x0 => x0.navigator,
      _4491: x0 => x0.trustedTypes,
      _4492: x0 => x0.sessionStorage,
      _4493: x0 => x0.localStorage,
      _4508: x0 => x0.hostname,
      _4602: x0 => x0.mediaDevices,
      _4618: x0 => x0.userAgent,
      _4826: x0 => x0.length,
      _6771: x0 => x0.signal,
      _6780: x0 => x0.length,
      _6840: () => globalThis.document,
      _6922: x0 => x0.head,
      _7252: (x0,x1) => { x0.id = x1 },
      _8598: x0 => x0.value,
      _8600: x0 => x0.done,
      _9302: x0 => x0.url,
      _9304: x0 => x0.status,
      _9306: x0 => x0.statusText,
      _9307: x0 => x0.headers,
      _9308: x0 => x0.body,
      _10129: x0 => x0.facingMode,
      _10343: x0 => x0.width,
      _10345: x0 => x0.height,
      _10351: x0 => x0.facingMode,
      _11871: (x0,x1) => { x0.height = x1 },
      _12065: (x0,x1) => { x0.objectFit = x1 },
      _12195: (x0,x1) => { x0.pointerEvents = x1 },
      _12493: (x0,x1) => { x0.transform = x1 },
      _12497: (x0,x1) => { x0.transformOrigin = x1 },
      _12561: (x0,x1) => { x0.width = x1 },
      _12929: x0 => x0.name,
      _13647: () => globalThis.console,
      _13675: x0 => x0.name,
      _13676: x0 => x0.message,
      _13677: x0 => x0.code,
      _13679: x0 => x0.customData,

    };

    const baseImports = {
      dart2wasm: dart2wasm,
      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
      S: new Proxy({}, { get(_, prop) { return prop; } }),

    };

    const jsStringPolyfill = {
      "charCodeAt": (s, i) => s.charCodeAt(i),
      "compare": (s1, s2) => {
        if (s1 < s2) return -1;
        if (s1 > s2) return 1;
        return 0;
      },
      "concat": (s1, s2) => s1 + s2,
      "equals": (s1, s2) => s1 === s2,
      "fromCharCode": (i) => String.fromCharCode(i),
      "length": (s) => s.length,
      "substring": (s, a, b) => s.substring(a, b),
      "fromCharCodeArray": (a, start, end) => {
        if (end <= start) return '';

        const read = dartInstance.exports.$wasmI16ArrayGet;
        let result = '';
        let index = start;
        const chunkLength = Math.min(end - index, 500);
        let array = new Array(chunkLength);
        while (index < end) {
          const newChunkLength = Math.min(end - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(a, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      "intoCharCodeArray": (s, a, start) => {
        if (s === '') return 0;

        const write = dartInstance.exports.$wasmI16ArraySet;
        for (var i = 0; i < s.length; ++i) {
          write(a, start++, s.charCodeAt(i));
        }
        return s.length;
      },
      "test": (s) => typeof s == "string",
    };


    

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      
      "wasm:js-string": jsStringPolyfill,
    });

    return new InstantiatedApp(this, dartInstance);
  }
}

class InstantiatedApp {
  constructor(compiledApp, instantiatedModule) {
    this.compiledApp = compiledApp;
    this.instantiatedModule = instantiatedModule;
  }

  // Call the main function with the given arguments.
  invokeMain(...args) {
    this.instantiatedModule.exports.$invokeMain(args);
  }
}
