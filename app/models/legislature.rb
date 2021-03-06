class Legislature < ActiveRecord::Base
  has_one :upper_chamber
  has_one :lower_chamber
  has_many :chambers
  has_many :committees
  has_many :primary_committees, :class_name => 'Committee', :conditions => 'committees.votesmart_parent_id is null'
  has_many :sub_committees, :class_name => 'Committee', :conditions => 'committees.votesmart_parent_id is not null'
  has_many :lower_committees
  has_many :upper_committees
  has_many :joint_committees
  belongs_to :state
  validates_uniqueness_of :name
  validates_presence_of :name

  has_many :sessions

  def self.congress
    find_by_name("United States Congress")
  end
end
