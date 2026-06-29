# frozen_string_literal: true

require 'sinatra'
require 'json'

enable :method_override
set :erb, escape_html: true

FILE_PATH = 'memos.json'

# ---------- 共通メソッド ----------
def load_memos
  if File.exist?(FILE_PATH)
    content = File.read(FILE_PATH)
    return [] if content.strip.empty?

    JSON.parse(content, symbolize_names: true)
  else
    []
  end
end

def save_memos(memos)
  File.write(FILE_PATH, JSON.pretty_generate(memos))
end

def next_id(memos)
  return 1 if memos.empty?

  memos.map { |memo| memo[:id] }.max + 1
end

# ✅ グローバル変数廃止
helpers do
  def memos
    @memos ||= load_memos
  end
end

# ---------- ルーティング ----------

# トップ画面
get '/' do
  @memos = memos
  erb :top
end

# 入力画面
get '/memos/new' do
  erb :newmemo
end

# 保存処理
post '/memos' do
  memos_list = memos

  memo = {
    id: next_id(memos_list),
    title: params[:title],
    content: params[:content]
  }

  memos_list << memo
  save_memos(memos_list)

  redirect '/'
end

# 詳細画面
get '/memos/:id' do
  @memo = memos.find { |m| m[:id] == params[:id].to_i }
  halt 404, 'メモが見つかりません' unless @memo

  erb :showmemo
end

# 編集画面
get '/memos/:id/edit' do
  @memo = memos.find { |m| m[:id] == params[:id].to_i }
  halt 404, 'メモが見つかりません' unless @memo

  erb :editmemo
end

# 更新処理
patch '/memos/:id' do
  memos_list = memos

  memo = memos_list.find { |m| m[:id] == params[:id].to_i }
  halt 404, 'メモが見つかりません' unless memo

  memo[:title] = params[:title]
  memo[:content] = params[:content]

  save_memos(memos_list)

  redirect "/memos/#{memo[:id]}"
end

# 削除処理
delete '/memos/:id' do
  memos_list = memos

  memos_list.reject! { |m| m[:id] == params[:id].to_i }

  save_memos(memos_list)

  redirect '/'
end
