# rubocop:disable all

require 'unloosen'

class Utils
  def self.build_js_object(**kwargs)
    object = JS.global[:Object].call(:call)

    kwargs.each do |(key, value)|
      object[key] = value
    end

    object
  end
end

content_script site: 'www.example.com' do
  # メモの初期化
  inner_object = Utils.build_js_object(text: '')
  outer_object = Utils.build_js_object(memo: inner_object)
  chrome.storage.local.set(outer_object)

  # popupからメッセージを受け取り、レスポンスを返す
  chrome.runtime.onMessage.addListener do |request, sender, sendResponse|
    sendResponse(window.getSelection().to_s)
  end
end

popup do
  memo_area = document.querySelector('#memo')

  # 既にメモが保存されている場合、取り出して描写する
  chrome.storage.local.get('memo') do |obj|
    memo = obj['memo']['text']
    if memo == null
      inner_object = Utils.build_js_object(text: '')
      outer_object = Utils.build_js_object(memo: inner_object)

      chrome.storage.local.set(outer_object)
    end

    memo_area.value = memo
  end

  # メモエリアに書いたメモの保存処理
  save_button = document.querySelector('#save')
  save_button.addEventListener 'click' do
    inner_object = Utils.build_js_object(text: memo_area.value)
    outer_object = Utils.build_js_object(memo: inner_object)

    chrome.storage.local.set(outer_object) do
      alert('保存が完了しました')
    end
  end

  # 範囲選択したテキストの取得+送信処理
  copy_button = document.querySelector('#copy')
  copy_button.addEventListener('click') do
    query_object = Utils.build_js_object(active: true, currentWindow: true)
    chrome.tabs.query(query_object) do |tabs|
      tab = tabs.at(0)
      chrome.tabs.sendMessage(tab[:id], 'popup: send request') do |response|
        # TODO
      end
    end
  end
end
