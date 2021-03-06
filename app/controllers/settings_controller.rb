# encoding: utf-8

class SettingsController < ApplicationController

    def index
       if current_user.has_role?(:admin)
            # On récupère les paramètres du logo
            if (Setting.all.length == 1)
                @setting = Setting.first
		    else
		        @setting = Setting.create
		    end
	        # On récupère les paramètres du serveur mail
	        if (WebmailConnection.all.length == 1)
			    @webmail_connection = WebmailConnection.first
			else 
			    @webmail_connection = WebmailConnection.create
			end
       else
            flash[:error] = t('app.cancan.messages.unauthorized').gsub('[action]', t('app.actions.do')).gsub('[undefined_article]', t('app.default.undefine_article_female')).gsub('[model]', t('app.controllers.Settings'))
			redirect_to root_url
			return false
       end
    end
    
    def update
    @setting = Setting.find(params[:setting][:id])
    if @setting.update_attributes(params[:setting])
			redirect_to url_for({ :controller => 'settings', :action => 'index' }), :notice => "Le logo a été modifié."
		else
			redirect_to url_for({ :controller => 'settings', :action => 'index' }), :alert => "Le fichier fourni doit être une image."
		end
    end

end

