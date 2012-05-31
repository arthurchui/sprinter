class SprintsController < ApplicationController
  # GET /sprints
  # GET /sprints.json
  def index
    @sprints = Sprint.all(:order => "end_date desc, xid desc")

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @sprints }
    end
  end

  # GET /sprints/1
  # GET /sprints/1.json
  def show
    @sprint = Sprint.find(params[:id])
    @cards = Card.where("sprint_id = #{@sprint.id}").order("card_updated desc")
    
    @features = @cards.where("card_type = 'Story'")
    @bugs = @cards.where("card_type = 'Bug'")
    @tasks = @cards.where("card_type = 'Task' OR card_type = 'Technical Task'")
    
    @to_do = @cards.where("status = 'Open'")
    @in_progress = @cards.where("status = 'In Progress'")
    @in_qa = @cards.where("status = 'Resolved'")
    @done = @cards.where("status = 'Closed'")

  
    @done_each_day = []
    @points_remaining = []
    @days = []
    @points = 0
    @target_points = []
    @target_high_points = []
    @target_low_points = [] 
    @days_in_sprint = (@sprint.end_date.to_date - @sprint.start_date.to_date).to_i+1
    @workdays_in_sprint = 0
    @points_this_sprint = @sprint.cards.sum('points')

    @sprint.start_date.upto(@sprint.end_date) do |day|
      if day.strftime('%A') != 'Saturday' && day.strftime('%A') != 'Sunday'
        @workdays_in_sprint = @workdays_in_sprint + 1
      end
    end 
    
    days_so_far = 0
    done_so_far = 0
    index = 0
    
    @sprint.start_date.upto(@sprint.end_date) do |day|
      if day.strftime('%A') != 'Saturday' && day.strftime('%A') != 'Sunday'
        index = index + 1   
        target_point = @points_this_sprint - @points_this_sprint/@workdays_in_sprint.to_f*index
        target_high_point = target_point + target_point * 0.2
        target_low_point = target_point - target_point * 0.2
        @target_points << target_point
        @target_high_points << target_high_point
        @target_low_points << target_low_point
        @days << day.strftime('%D').to_s

        if day.to_date <= Time.now.to_date
          days_so_far = days_so_far + 1
          done_this_day = 0
          @sprint.cards.each do |card|
            if card.status.to_s == 'Closed' && card.card_updated.to_date == day.to_date
              done_this_day = done_this_day + card.points.to_i
            end
          end
          done_so_far = done_so_far + done_this_day
          @points_remaining << @points_this_sprint - done_so_far      
          if @points_this_sprint - done_so_far < target_low_point
            @progress_status = 'progress-warning'
          elsif @points_this_sprint - done_so_far > target_low_point && @points_this_sprint - done_so_far < target_high_point
            @progress_status = 'progress-success'
          elsif @points_this_sprint - done_so_far > target_high_point
            @progress_status = 'progress-danger'
          else
            @progress_status = 'progress-info'
          end  
          @sprint_progress = days_so_far/@workdays_in_sprint.to_f*100
        end 
        
      end
    end
    
    
    
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @sprint }
    end
  end

  # GET /sprints/new
  # GET /sprints/new.json
  def new
    @sprint = Sprint.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @sprint }
    end
  end

  # GET /sprints/1/edit
  def edit
    @sprint = Sprint.find(params[:id])
  end

  # POST /sprints
  # POST /sprints.json
  def create
    @sprint = Sprint.new(params[:sprint])

    respond_to do |format|
      if @sprint.save
        format.html { redirect_to @sprint, notice: 'Sprint was successfully created.' }
        format.json { render json: @sprint, status: :created, location: @sprint }
      else
        format.html { render action: "new" }
        format.json { render json: @sprint.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /sprints/1
  # PUT /sprints/1.json
  def update
    @sprint = Sprint.find(params[:id])

    respond_to do |format|
      if @sprint.update_attributes(params[:sprint])
        format.html { redirect_to @sprint, notice: 'Sprint was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @sprint.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sprints/1
  # DELETE /sprints/1.json
  def destroy
    @sprint = Sprint.find(params[:id])
    @sprint.destroy

    respond_to do |format|
      format.html { redirect_to sprints_url }
      format.json { head :no_content }
    end
  end
  
  def reload
    project = HTTParty.get("http://jira.wantsa.com:38881/rest/api/2/project/WP",{:basic_auth => auth})
    
    project['versions'].each do |sprint|
      @sprint = Sprint.find_by_xid(sprint['id'])
      if !@sprint
        @sprint = Sprint.create({:xid => sprint['id'], :name => sprint['name']})
      end
      
      sprint = HTTParty.get("http://jira.wantsa.com:38881/rest/api/2/search?jql=fixVersion=#{@sprint.xid}",{:basic_auth => auth})
      sprint['issues'].each do |sprint_card|
        @card = Card.find_by_key(sprint_card['key'])
        if !@card
          @card = Card.create({ :key => sprint_card['key'] })
        end
        
        @card.summary = sprint_card['fields']['summary']
        @card.sprint_id = @sprint.id
        @card.description = sprint_card['fields']['description']
        if sprint_card['fields']['assignee']
          @card.assignee = sprint_card['fields']['assignee']['displayName']
        else
          @card.assignee = 'Unassigned'
        end
        @card.card_created = sprint_card['fields']['created']
        @card.card_updated = sprint_card['fields']['updated']
        @card.card_type = sprint_card['fields']['issuetype']['name']
        @card.points = sprint_card['fields']['customfield_10013']
        @card.status = sprint_card['fields']['status']['name']
        @card.save! 
      end
    end
    redirect_to sprints_path, notice: "Sprints reloaded."

  end
  
end