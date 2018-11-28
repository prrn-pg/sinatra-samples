require 'sinatra'
require 'sinatra/reloader'
require 'digest/md5'
require 'time'
require 'date'

todos = {}
FILENAME = "todo.json"
@todos = todos


class Todo
  attr_accessor :title, :content, :date, :priority, :id
  def initialize
    @date = Time.new.iso8601(6)
    @id = Digest::MD5.hexdigest(@date.to_s)
  end
  def profile_to_hash
    self.instance_variables.map{|var|
      # そのままだと頭に@つきになってしまうので
      # [var.match(/[\w\d]+/).to_s, self.instance_variable_get(var)]
      # と思ったけど@ごと文字列にします
      [var, self.instance_variable_get(var)]
    }.to_h
  end
end

# エントリポイント
get '/' do
  if File.exists?(FILENAME)
    File.open(FILENAME, 'r+') do  |file|
      # 読み込み
      todos = JSON.load(file)
    end
  else
    File.open(FILENAME, 'w+') do |file|
      file.puts('{}')
    end
  end
  @todos = todos
  erb :top
end

get '/todo/new' do
  erb :new
end

post '/' do
  if params[:todocontent].split.size==0 && params[:todotitle].split.size==0
    status 204
    redirect '/'
  end
  todo = Todo.new()
  todo.content = params[:todocontent].strip
  todo.title = params[:todotitle].strip
  todos[todo.id] = todo.profile_to_hash
  # ここに保存する処理
  updatelist(todos, FILENAME)
  @todos = todos
  status 201
  redirect '/'
end

# 編集済データ更新(patchメソッド)
patch '/todo/:id' do
  todos[params["id"]]["@title"] = params[:todotitle].strip
  todos[params["id"]]["@content"] = params[:todocontent].strip
  # 時間を編集した時点に更新
  todos[params["id"]]["date"] = Time.new.iso8601(6)
  updatelist(todos, FILENAME)
  @todos = todos
  # もうちょい検証が必要..?
  status 201
  redirect '/'
end

get /\/todo\/([\w\d]+)/ do |i|
  @todo_id = i
  @todo_title = todos[i]["@title"].strip
  @todo_content = todos[i]["@content"].strip
  erb :todo
end

# deleteメソッド
delete '/todo/:id' do
  todos.delete(params["id"])
  updatelist(todos, FILENAME)
  @todos = todos
  status 204
  redirect '/'
end

get /\/todo\/edit\/([\w\d]+)/ do |i|
  @todo_id = i
  @todo_title = todos[i]["@title"].strip
  @todo_content = todos[i]["@content"].strip
  erb :edit
end

helpers do
  # jsonを現在のtodoに合わせてアップデート
  def updatelist(dict, file)
    open(file, 'w') do |f|
      JSON.dump(dict, f)
    end
  end
end 
