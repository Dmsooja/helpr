class Api::V1::ConversationsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_conversation, only: [:show, :destroy]
    
    def index
        @conversations = Conversation.where("helpr_id = #{current_user.id} OR requester_id = #{current_user.id}")
        render json: @conversations
    end
    
    def show
        puts "REQUEST is :: #{Request.where(:id => params[:request_id])}"
        # puts "REQUEST COUNTER is :: #{Request.where(params[:request_id]).response_counter}"
        # @conversation = Conversation.find(params[:id])
        # render json: ConversationSerializer.new(@conversation)
        render json: @conversation
    end
    
    def get_user_full_name
        user_first_name = current_user.first_name
        user_last_name = current_user.last_name
        render json: user_first_name + " " + user_last_name
    end

    def get_user_avatar
        user_avatar = current_user.first_name
        render json: user_avatar
    end

    def create
        
        #     @response = current_user.responses.build(response_params)
        #     @current_request = Request.where(:id => params[:request_id])
    #         # @current_request = Request.find(:id => params[:request_id])
        #     if Request.find(params[:request_id]).response_counter < 5
        #       Request.find(params[:request_id]).update(:response_counter => Request.find(params[:request_id]).response_counter + 1, :request_status => Request.find(params[:request_id]).request_status = "pending")
        #       if Request.find(params[:request_id]).response_counter == 4
        #         Request.find(params[:request_id]).update(:response_counter => Request.find(params[:request_id]).response_counter + 1, :fulfilled => Request.find(params[:request_id]).fulfilled = true, :request_status => Request.find(params[:request_id]).request_status = "hidden")
        #     #     if Request.find(params[:request_id]).response_counter == 5
        #     #       handle_max_responses
        #       else
        #         handle_unauthorized
        #       end
        #     end
        #   end
        conversation_params[:helpr_id] = current_user.id
        counter = Request.find(params[:request_id]).response_counter
        @conversation = Conversation.new(title: conversation_params[:title], requester_id: conversation_params[:requester_id], request_id: conversation_params[:request_id], helpr_id: current_user.id)
        # @conversation = current_user.conversations.build(conversation_params)
        if @conversation.save
            serialized_data = ActiveModelSerializers::Adapter::Json.new(ConversationSerializer.new(@conversation)).serializable_hash
            ActionCable.server.broadcast 'conversations_channel', serialized_data
            render json: @message

        end
    end

    # def create
    # end
    def destroy
        Conversation.find(params[:request_id]).update(:response_counter => Conversation.find(params[:request_id]).response_counter - 1)
        if authorized?
          @conversation.destroy
            head :no_content
        else
          handle_unauthorized
        end
      end
      
    private
        def set_conversation
            @conversation = Conversation.find(params[:id])
        end

        def conversation_params
            params.require(:conversation).permit(:title, :request_id, :selected, :requester_id, :helpr_id)
        end

        def authorized?
            @conversation.user == current_user
        end
    
        def handle_unauthorized
            respond_to do
                render json: { error: "You are not authorized to perform this action.", status: 401 }, status: 401
            end
        end

        def handle_max_responses
            respond_to do
              render json: { error: "You can't respond to a request that already has 5 responses", status: 401 }, status: 401
            end
        end
end
