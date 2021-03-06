class Api::V1::ConversationsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_conversation, only: [:show, :destroy, :update, :destroy]

    def index
        @conversations = Conversation.where("helpr_id = #{current_user.id} OR requester_id = #{current_user.id}")
        render json: @conversations
    end

    def show
        @conversation = Conversation.find(params[:id])
        render json: @conversation
    end

    def get_responses_by_user_id
          @user_responses = Conversation.where("helpr_id = ?", current_user.id)
          render json: @user_responses
    end

    def get_responses_help
        @user_help = Conversation.where("requester_id = ?", current_user.id)
        render json: @user_help
    end


    def create
        request = Request.find(params[:request_id])
        counter = request.response_counter
        if request.user_id == current_user.id
            handle_owner
        else
            if Conversation.where("helpr_id = #{current_user.id} AND request_id = #{params[:request_id]}").exists?
                p "PARAMS ARE #{params[:request_id]}"
                handle_already_responded
            else

                if request.response_counter == 5
                    handle_max_responses

                else
                    if counter < 5
                        if request.response_counter == 4
                            request.update(:response_counter => request.response_counter + 1, :request_status => request.request_status = "hidden")
                        else
                            puts "COUNTER IS NOW:: #{counter}"
                            request.update(:response_counter => request.response_counter + 1, :request_status => request.request_status = "pending")
                            @conversation = Conversation.new(title: conversation_params[:title], requester_id: conversation_params[:requester_id], request_id: conversation_params[:request_id], helpr_id: current_user.id)
                        end
                    end
                    if @conversation.save
                        serialized_data = ActiveModelSerializers::Adapter::Json.new(ConversationSerializer.new(@conversation)).serializable_hash
                        ActionCable.server.broadcast 'conversations_channel', serialized_data
                        render json: @conversation
                    end

                end
            end
        end
    end

    def update
        p "IS REFFERED #{is_requester?}"
        # if is_requester?
          if @conversation.update(conversation_params)
          else
            render json: @request.errors, status: :unprocessable_entity
          end
        # else
        #   handle_unauthorized
        # end
    end

    def destroy
        request = Request.find(@conversation.request_id)
        request.update(:response_counter => request.response_counter - 1, :request_status => request.request_status = "pending")
          @conversation.destroy
      end

    private

        def set_conversation
            @conversation = Conversation.find(params[:id])
        end

        def conversation_params
            params.require(:conversation).permit(:title, :request_id, :selected, :requester_id, :helpr_id)
        end

        def destroy_authorized?
            @conversation.requester_id == current_user.id
        end

        def is_requester?
            @conversation.requester_id = current_user.id
        end

        def is_helpr?
            @conversation.helpr_id = current_user.id
        end

        def handle_unauthorized
            render body: "You are not authorized to perform this action.", status: 401
        end

        def handle_owner
            render body: "You can\'t respond to your own request", status: 403
        end

        def handle_already_responded
            render body: "You already responded to this request, check your conversations", status: 403
        end

        def handle_max_responses
            render body: "You cannot respond to a request that already has 5 responses, try again when you see this request on the map", status: 403
        end
end
