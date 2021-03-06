GooglePlay::Application.routes.draw do
  resources :signin, :only => [:index] do
    collection do
      post :connect
      post :disconnect
      post :save_user
      get :refresh_connection
    end
  end

  resources :activities, :only => [:index, :show] do
    resources :comments, :only => [:index]
    collection do
      get :search
    end
  end

  resources :comments, :only => [:show]

  resources :calendars, :only => [:show, :create, :update, :destroy] do
    resources :calendar_events, :only => [:index, :new, :show, :create, :update, :destroy], :path => 'events', :as => 'events' do
      member do
        post :move
        get :destroy_show, path: 'destroy'
      end
      collection do
        post :quick_add
      end
    end
    member do
      post :clear
    end
  end

  resources :calendar_lists, :only => [:index, :show, :create, :update, :destroy]

  resources :circles do
    member do
      get :destroy_show, path: 'destroy'
      post :add_message
      post :add_wallpin
      post :delete_item
    end
    collection do
      get :circles_names
    end
  end

  resources :colors, except: [:index, :show, :new, :create, :edit, :update, :destroy] do
    collection do
      get :calendar, :as => 'calendar'
      get :event, :as => 'event'
    end
  end

  resources :files, :only => [:index, :show, :create, :update, :destroy] do
    resources :file_comments, :only => [:index, :show, :create, :update, :destroy], :path => 'comments', :as => 'comments' do
      resources :replies, :only => [:index, :show, :create, :update, :destroy]
      collection do
        get :comments_show, :path => "show", :as => "show"
      end
    end
    member do
      post :copy
      post :touch
      post :trash
      post :untrash
      get :destroy_show, path: 'destroy'
      get :copy_show, path: 'copy'
      get :share
    end
    collection do
      post :insert_new
      post :share_files
      get :circle_files
      get :search_files
    end
  end

  resources :peoples, :only => [:index, :show] do
    collection do
      get :search
      get :monea_email_search
      get :list_by_activity
      get :circle_peoples
      post :add_people
      post :add_friend_to_team
      post :remove_team_member
    end
  end

  resources :task_lists, :only => [:index, :show, :create, :update, :destroy] do
    resources :tasks, :only => [:index, :show, :new, :create, :update, :destroy] do
      member do
        put :complete_task
        get :destroy_show, path: 'destroy'
        get :complete_show, path: 'complete'
      end
      collection do
        post :clear
      end
    end
    member do
      get :destroy_show, path: 'destroy'
    end
    collection do
      post :create_task
    end
  end

  root 'signin#index'
end
