package abi35_0_0.host.exp.exponent.modules.api.components.webview.events

import abi35_0_0.com.facebook.react.bridge.WritableMap
import abi35_0_0.com.facebook.react.uimanager.events.Event
import abi35_0_0.com.facebook.react.uimanager.events.RCTEventEmitter

/**
 * Event emitted when shouldOverrideUrlLoading is called
 */
class TopShouldStartLoadWithRequestEvent(viewId: Int, private val mData: WritableMap) : Event<TopShouldStartLoadWithRequestEvent>(viewId) {
  companion object {
    const val EVENT_NAME = "topShouldStartLoadWithRequest"
  }

  init {
    mData.putString("navigationType", "other")
  }

  override fun getEventName(): String = EVENT_NAME

  override fun canCoalesce(): Boolean = false

  override fun getCoalescingKey(): Short = 0

  override fun dispatch(rctEventEmitter: RCTEventEmitter) =
    rctEventEmitter.receiveEvent(viewTag, EVENT_NAME, mData)
}
