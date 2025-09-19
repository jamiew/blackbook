class Like < ApplicationRecord
  belongs_to :user
  belongs_to :object, polymorphic: true
  
  validates :user_id, presence: true
  validates :object_id, presence: true
  validates :object_type, presence: true
  validates :user_id, uniqueness: { scope: [:object_id, :object_type] }
end