package hx.utils.inputs;

#if (html5 && !wechat)
import hx.display.Stage;
import hx.display.ITabFocusable;
import hx.events.Keyboard;
import hx.events.KeyboardEvent;
import hx.utils.KeyboardTools;
import js.Browser;

/** 将浏览器中的 Tab 交给当前接口焦点所在的舞台，统一处理原生和引擎事件。 */
class HTML5FocusNavigation {
	private static var __initialized:Bool = false;

	/**
	 * 当前宿主是否真有浏览器全局 `window`。
	 *
	 * `html5` 构建也会被编进 **纯 node** 进程跑无头自检（本仓库 `tools/*-check/run.js` 就是这么做的：
	 * 只有 location/navigator 桩，没有 DOM）。那种情况下 `window` 是**未声明的标识符**，
	 * 直接写 `Browser.window == null` 会抛 `ReferenceError`（在 `==` 判空之前就炸），
	 * 而 `hx.core.Hxmaker.topView = new Stage()` 是**类静态初始化** ⇒ 任何链接到 Hxmaker 的工具
	 * 一 require 就挂，连带 `make check-events` 之类的门禁全废。
	 * 先用 `typeof` 判"有没有这个全局名"，再判 null。
	 */
	private static function __hasWindow():Bool {
		return js.Syntax.code("typeof window != 'undefined' && window != null");
	}

	public static function init():Void {
		if (__initialized || !__hasWindow() || !Reflect.isFunction(Reflect.field(Browser.window, "addEventListener")))
			return;
		__initialized = true;
		// 捕获阶段先接管，避免隐藏输入框与 OpenFL 后端重复处理同一次 Tab。
		Browser.window.addEventListener("keydown", onKeyDown, true);
	}

	/** 页面中的其他原生编辑控件不使用引擎的 Tab 导航。 */
	public static function isExternalEditorFocused():Bool {
		if (!__hasWindow() || Browser.document == null)
			return false;
		var active = Browser.document.activeElement;
		return active != null && active != HTML5TextInputUtils.textureArea
			&& (active.tagName == "INPUT" || active.tagName == "TEXTAREA" || Reflect.field(active, "isContentEditable") == true);
	}

	private static function onKeyDown(event:js.html.KeyboardEvent):Void {
		if (event.key != "Tab" && event.keyCode != Keyboard.TAB)
			return;
		var current = @:privateAccess Stage.__focus;
		if (current == null || current.stage == null || current.isDisposed || !(current is ITabFocusable))
			return;
		// 页面中其他原生编辑控件已有焦点时，保留它们自己的 Tab 行为。
		if (isExternalEditorFocused())
			return;
		var engineEvent = new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true);
		engineEvent.keyCode = Keyboard.TAB;
		engineEvent.shiftKey = event.shiftKey;
		engineEvent.ctrlKey = event.ctrlKey;
		engineEvent.altKey = event.altKey;
		engineEvent.metaKey = event.metaKey;
		engineEvent.isComposing = event.isComposing || event.keyCode == 229 || HTML5TextInputUtils.isComposing();
		if (event.defaultPrevented)
			engineEvent.preventDefault();
		event.stopImmediatePropagation();
		current.stage.handleKeyboardEvent(engineEvent);
		if (engineEvent.isDefaultPrevented)
			event.preventDefault();
		// 与后端原有顺序一致：事件分发结束后更新按键状态。
		@:privateAccess KeyboardTools.onKeyDown(Keyboard.TAB);
	}
}
#end
