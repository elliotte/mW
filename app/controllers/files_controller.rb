class FilesController < ApplicationController

	before_action :discover_api, except: [:share_files]
	before_action :get_file, only: [:show, :update, :destroy_show, :copy_show]

	def index
    	# Get the list of files in drive
	    response = $client.execute(:api_method => @drive.files.list)
	    render json: response.data.to_json
	end

	def show
	    render json: @response.data.to_json
	end

	def circle_files
		@team_files = Circle.find(params[:id]).team_files
		render json: @team_files
	end

	def create
		# Create the file in drive
		#need to clean up without impacting main file creates and teamFile.new
	  	file = @drive.files.insert.request_schema.new({
	    	'title' => params[:file].original_filename,
    		'mimeType' => params[:file].content_type
	  	})

	  	if params[:circle_id].present?
	  		file.properties = [{"key" => "circle_id", "value" => params[:circle_id]}]
	  	end

	  	media = Google::APIClient::UploadIO.new(params[:file].tempfile.path, params[:file].content_type)
	  	response = $client.execute(
	    	:api_method => @drive.files.insert,
	    	:body_object => file,
	    	:media => media,
	    	:parameters => {
	      		'uploadType' => 'multipart',
	      		'alt' => 'json' })

	  	if params[:circle_id].present?
		  	TeamFile.create(circle_id: params[:circle_id], file_id: response.data.id)
		  	@circle = Circle.find(params[:circle_id])
		  	team_members = @circle.team_members
		    if team_members.present?
		    	team_members.each do |team_member|
		    		user = User.find_by(google_id: team_member.google_id)
		    		if user
		    			new_permission = @drive.permissions.insert.request_schema.new({
						    'value' => user.email,
						    'type' => "user",
						    'role' => "reader"
						})

						result = $client.execute(:api_method => @drive.permissions.insert,
											    :body_object => new_permission,
											    :parameters => { 'fileId' => response.data.id, 'emailMessage' => 'Shared via monea.build' })
		    		end
		    	end
		    end
		    unless current_user.id == @circle.user_id
		    	@circle_owner = User.find(@circle.user_id)
		    	new_permission = @drive.permissions.insert.request_schema.new({
						    'value' => @circle_owner.email,
						    'type' => "user",
						    'role' => "reader"
						})
				result = $client.execute(:api_method => @drive.permissions.insert,
											    :body_object => new_permission,
											    :parameters => { 'fileId' => response.data.id })
		    end
		end

	    # render json: response.data.to_json
	    if params[:circle_id].present?
	    	redirect_to circle_path(params[:circle_id])
	    else
	    	redirect_to root_path
	    end
	end

	def insert_new
	  # Insert a template file
	  file = @drive.files.insert.request_schema.new({
	    'title' => params[:title],
	    'mimeType' => params[:mimeType]
	  })
	  media = ""
	  if params[:mimeType] == 'application/vnd.google-apps.spreadsheet'
	  	media = Google::APIClient::UploadIO.new("#{Rails.root}/app/files/monea-build.csv", 'text/csv')
	  else
	  	media = Google::APIClient::UploadIO.new("#{Rails.root}/app/files/monea-build.txt", 'text/plain')
	  end
	  result = $client.execute(
	    :api_method => @drive.files.insert,
	    :body_object => file,
	    :media => media,
	    :parameters => {
	      'uploadType' => 'multipart',
	      'alt' => 'json',
	      'convert' => true })

      respond_to do |format|
	      format.js { @file = result.data }
	   end
	end

	def update
	    file = @response.data

	    file.title = params[:title] if params[:title].present?
	    file.description = params[:description] if params[:description].present?
	    file.mime_type = params[:mime_type] if params[:mime_type].present?

	    media = Google::APIClient::UploadIO.new(params[:file].tempfile.path, params[:file].content_type)

	    result = $client.execute(
	      	:api_method => @drive.files.update,
	      	:body_object => file,
	      	:media => media,
	      	:parameters => { 'fileId' => file.id,
	                       'newRevision' => false,
	                       'uploadType' => 'multipart',
	                       'alt' => 'json' })

	    render json: result.data.to_json
	end

	def destroy
		# Delete the file from drive
	    response = $client.execute(:api_method => @drive.files.delete,
    							:parameters => { 'fileId' => params[:id] })

	    teams_file_belongs_to = TeamFile.all.where(file_id: params[:id])
	    teams_file_belongs_to.each do |t_file|
	    	t_file.destroy
	    end
	    # render json: response.data.to_json
	    respond_to do |format|
	      	format.js { @div_id = params[:id] }
	    end
	end

	def destroy_show
	    respond_to do |format|
	      	format.html
	      	format.js { @file = @response.data }
	    end
  	end

	def copy
		# Creates a copy of the specified file.
		copied_file = @drive.files.copy.request_schema.new({ 'title' => params[:title] })

		response = $client.execute(
		    :api_method => @drive.files.copy,
		    :body_object => copied_file,
		    :parameters => { 'fileId' => params[:id] })

		# render json: response.data.to_json
		redirect_to root_path
	end

	def copy_show
	    respond_to do |format|
	      	format.html
	      	format.js { @file = @response.data }
	    end
  	end

  	def share
  		respond_to do |format|
	      	format.html
	      	format.js { @file_id = params[:id] }
	    end
  	end

  	def share_files
  		
  		if params[:teams].present?
	        teams = params[:teams].split(',')
	        teams.each do |team|
	        		#teamFile array for share_team_files method flexbility
	        		teamfile = [TeamFile.create(circle_id: team, file_id: params[:file_id])]
	        		
	        		circle = Circle.find(team)
				  	team_members = circle.team_members

				    if team_members.present?
			    		team_members.each do |team_member|
			    		user = User.find_by(google_id: team_member.google_id)
			    		  Circle.share_team_files($client, user, teamfile)
				    	end
					end
	        end
	    end
	    if params[:search_files_box].present?

	    	teams = [params[:circle_id]]
	        teams.each do |team|
	        		params[:file_id] = params[:search_files_box]
	        		#teamFile array for share_team_files method flexbility
	        		teamfile = [TeamFile.create(circle_id: team, file_id: params[:file_id])]
	        		
	        		circle = Circle.find(team)
				  	team_members = circle.team_members

				    if team_members.present?
			    		team_members.each do |team_member|
			    		user = User.find_by(google_id: team_member.google_id)
			    		  Circle.share_team_files($client, user, teamfile)
				    	end
					end
	        end
  		end
	    #to add success counter on permission share
	   	respond_to do |format|
	      	format.html 
	      	format.js { @file_id = params[:file_id] }
	    end
  	end

	def touch
		# Set the file's updated time to the current server time. Update a file's modified date.
		response = $client.execute(:api_method => @drive.files.touch,
    							:parameters => { 'fileId' => params[:id] })

	    render json: response.data.to_json
	end

	def trash
		# Moves a file to the trash.
		response = $client.execute(:api_method => @drive.files.trash,
    							:parameters => { 'fileId' => params[:id] })

	    render json: response.data.to_json
	end

	def untrash
		# Restores a file from the trash.
		response = $client.execute(:api_method => @drive.files.untrash,
    							:parameters => { 'fileId' => params[:id] })

	    render json: response.data.to_json
	end

	def search_files
		response = $client.execute(:api_method => @drive.files.list, :parameters => {"q" => "title contains '#{params[:q]}'" })
		files = []
		response.data.items.each do |file|
			files.push({ id: file.id, name: file.title})
		end
		render json: files.to_json
	end

	private

	def discover_api
		# Authorizing the client and constructing a Google+ service.
		@drive = $client.discovered_api('drive', 'v2')
	end

	def get_file
    	# Get the file from drive
	    @response = $client.execute(:api_method => @drive.files.get,
    								:parameters => { 'fileId' => params[:id] })
	end
end
