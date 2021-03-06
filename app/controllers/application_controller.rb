class ApplicationController < ActionController::Base
    protect_from_forgery with: :null_session
    before_action :configure_permitted_parameters,
        if: :devise_controller?

    protected
        def configure_permitted_parameters
            devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:first_name, :last_name, :email, :password, :gov_approved_id)}
            devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:first_name, :last_name, :email, :password, :current_password, :password_confirmation, :gov_approved_id)}
        end
    
end
