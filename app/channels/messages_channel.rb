class MessagesChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
    puts "MESSAGE ROOM #{params[:room]}"
    room = Conversation.find(params[:room])
    stream_for room
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
