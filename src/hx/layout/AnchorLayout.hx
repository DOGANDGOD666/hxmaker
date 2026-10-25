package hx.layout;

import hx.core.Hxmaker;
import hx.utils.ScaleUtils;
import hx.display.Image;
import hx.display.DisplayObject;

/**
 * 
 */
class AnchorLayout extends Layout {
	/**
	 * 只在目标值真的变化时才写 `width` / `height`。
	 *
	 * ⚠ 2026-10-26 修（主界面 158fps → 60fps 的回归）：拉伸（left+right / top+bottom 等）分支原来
	 * **每帧无条件写一次** `object.width/height`，而 `DisplayObjectContainer.set_width/set_height`
	 * 一被写就 `__layoutDirty = true`；`DisplayObjectContainer.__prepareWorldTransform()` 又**每帧**
	 * 调 `__updateLayout()` ⇒「布局 → 写宽 → 置脏 → 下一帧再布局」自激，整棵树每帧重排。
	 * 写同值是幂等操作（`set_width` 内部只是 `__width = v; scaleX = v / bounds.width`），
	 * 所以"值没变就不写"不改变任何布局结果，只是不再自激。
	 */
	private static function __applyWidth(object:DisplayObject, value:Float):Void {
		if (object.width != value)
			object.width = value;
	}

	/** 同 `__applyWidth`。 */
	private static function __applyHeight(object:DisplayObject, value:Float):Void {
		if (object.height != value)
			object.height = value;
	}

	override function update(children:Array<DisplayObject>) {
		super.update(children);
		if (children.length == 0)
			return;
		var parent = children[0].parent;
		// 父节点的宽度
		var parentWidth = parent.width;
		// 父节点的高度
		var parentHeight = parent.height;
		for (object in children) {
			if (object.layoutData != null && object.layoutData is AnchorLayoutData) {
				var layoutData:AnchorLayoutData = cast object.layoutData;
				if (layoutData.isFill) {
					if (object is Image) {
						var image:Image = cast object;
						if (image.data != null) {
							var scale = ScaleUtils.mathScale(Hxmaker.engine.stageWidth, Hxmaker.engine.stageHeight, image.data.width, image.data.height,
								false, false, true);
							image.scale = scale;
						}
					}
				}

				// 百分比宽高兼容
				if (layoutData.percentWidth != null) {
					__applyWidth(object, parentWidth * layoutData.percentWidth / 100);
				}
				if (layoutData.percentHeight != null) {
					__applyHeight(object, parentHeight * layoutData.percentHeight / 100);
				}

				if (layoutData.left != null && layoutData.right != null) {
					// 左右拉伸
					object.x = layoutData.left;
					__applyWidth(object, parentWidth - layoutData.left - layoutData.right);
				} else if (layoutData.left != null && layoutData.horizontalCenter != null) {
					// 左中拉伸
					object.x = layoutData.left;
					__applyWidth(object, parentWidth / 2 + layoutData.horizontalCenter - layoutData.left);
				} else if (layoutData.right != null && layoutData.horizontalCenter != null) {
					// 右中拉伸
					object.x = parentWidth / 2 + layoutData.horizontalCenter;
					__applyWidth(object, parentWidth / 2 - layoutData.horizontalCenter - layoutData.right);
				} else if (layoutData.left != null) {
					// 左位移
					object.x = layoutData.left;
				} else if (layoutData.right != null) {
					// 右位移
					object.x = parentWidth - object.width - layoutData.right;
				} else if (layoutData.horizontalCenter != null) {
					object.x = parentWidth / 2 - object.width / 2 + layoutData.horizontalCenter;
				}

				// 上下的逻辑处理
				if (layoutData.top != null && layoutData.bottom != null) {
					// 上下拉伸
					object.y = layoutData.top;
					__applyHeight(object, parentHeight - layoutData.top - layoutData.bottom);
				} else if (layoutData.top != null && layoutData.verticalCenter != null) {
					// 上中拉伸
					object.y = layoutData.top;
					__applyHeight(object, parentHeight / 2 + layoutData.verticalCenter - layoutData.top);
				} else if (layoutData.bottom != null && layoutData.verticalCenter != null) {
					// 下中拉伸
					object.y = parentHeight / 2 + layoutData.verticalCenter;
					__applyHeight(object, parentHeight / 2 - layoutData.verticalCenter - layoutData.bottom);
				} else if (layoutData.top != null) {
					// 上位移
					object.y = layoutData.top;
				} else if (layoutData.bottom != null) {
					object.y = parentHeight - object.height - layoutData.bottom;
				} else if (layoutData.verticalCenter != null) {
					object.y = parentHeight / 2 - object.height / 2 + layoutData.verticalCenter;
				}
			}
		}
	}
}
