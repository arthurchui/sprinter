class Sprint < ActiveRecord::Base
  include ApplicationHelper
  has_many :cards
  attr_accessible :end_date, :name, :start_date, :xid

  def business_days_between(date1, date2)
    business_days = 0
    date = date2
    while date >= date1
     business_days = business_days + 1 unless date.saturday? or date.sunday?
     date = date - 1.day
    end
    business_days
  end

  def reload_sprint_list
    project = HTTParty.get("http://jira.wantsa.com:38881/rest/api/2/project/WP",{:basic_auth => auth})
    
    project['versions'].each do |sprint|
      @sprint = Sprint.find_by_xid(sprint['id'])
      if !@sprint
        @sprint = Sprint.create({:xid => sprint['id'], :name => sprint['name']})
      end
    end
  end

  def reload_sprint(id)
    @sprint = Sprint.find(id)
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
  
  def velocity
    self.cards.sum('points')
  end
  
  
  def type_count(type)
    self.cards.where("card_type = '#{type}'").count
  end
  
end
