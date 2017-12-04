# Dradis Note objects are associated with a Node. It is possible to create a
# tree structure of Nodes to hierarchically structure the information held
# in the repository.
#
# Each Node has a :parent node and a :label. Nodes can also have many
# Attachment objects associated with them.
class Node < ApplicationRecord
  include NodeProperties

  module Types
    DEFAULT = 0
    HOST = 1
    METHODOLOGY = 2
    ISSUELIB = 3
    USER_TYPES = [DEFAULT, HOST]
  end

  acts_as_tree counter_cache: true, order: :label

  # -- Relationships --------------------------------------------------------
  has_many :notes, dependent: :destroy
  has_many :evidence, dependent: :destroy
  has_many :issues, -> { distinct }, through: :evidence
  has_many :activities, as: :trackable

  def nested_activities
    sql = "(`activities`.`trackable_type`='Node' AND "\
          " `activities`.`trackable_id`=#{id})"

    # Don't check for note/evidence activities unless we actually have
    # notes/evidence, because "IN ()" isn't valid MySQL.

    # Cache ids in a local variable so we don't make the same SQL request twice
    if (e_ids = evidence_ids).any?
      sql << " OR (`activities`.`trackable_type`='Evidence' AND "\
             "`activities`.`trackable_id` IN (#{e_ids.join(",")}))"
    end
    if (n_ids = note_ids).any?
      sql << " OR (`activities`.`trackable_type`='Note' AND "\
             " `activities`.`trackable_id` IN (#{n_ids.join(",")}))"
    end
    Activity.where(sql)
  end


  # -- Callbacks ------------------------------------------------------------
  before_destroy :destroy_attachments
  before_save do |record|
    record.type_id = Types::DEFAULT unless record.type_id
    record.position = 0 unless record.position
  end

  # -- Validations ----------------------------------------------------------
  validates_presence_of :label
  validate :parent_node, if: Proc.new { |node| node.parent_id }

  # -- Scopes ---------------------------------------------------------------
  scope :in_tree, -> {
    user_nodes.roots
  }

  scope :user_nodes, -> {
    where("type_id IN (?)", Types::USER_TYPES)
  }


  # -- Class Methods --------------------------------------------------------
  # Returns or creates the Node that acts as container for all Issues in a
  # given project
  def self.issue_library
    find_or_create_by(label: 'All issues', type_id: Node::Types::ISSUELIB)
  end

  # Returns or creates the Node that acts as container for all Methodologies in
  # a given project
  def self.methodology_library
    find_or_create_by(label: 'Methodologies', type_id: Node::Types::METHODOLOGY)
  end

  # When Upload plugins create new nodes, they'll do so under this parent node
  def self.plugin_parent_node
    find_or_create_by(label: ::Configuration.plugin_parent_node)
  end

  # Security scanner output files uploaded via the Upload Manager use this node
  # as container
  def self.plugin_uploads_node
    find_or_create_by(label: ::Configuration.plugin_uploads_node)
  end

  # If an item is recovered from the trash, but we can't reassign it to its
  # Node because its Node has also been deleted, it will be assigned to this
  # node:
  def self.recovered
    find_or_create_by(label: 'Recovered', type_id: Node::Types::DEFAULT)
  end

  # -- Instance Methods -----------------------------------------------------
  def ancestor_of?(node)
    node && node.ancestors.include?(self)
  end

  # Return all the Attachment objects associated with this Node.
  def attachments
    Attachment.find(:all, :conditions => {:node_id => self.id})
  end

  def user_node?
    Types::USER_TYPES.include?(self.type_id)
  end

  private
  # Whenever a node is deleted all the associated attachments have to be
  # deleted too
  def destroy_attachments
    attachments_dir = Attachment.pwd.join(self.id.to_s)
    FileUtils.rm_rf attachments_dir if File.exists?(attachments_dir)
  end

  def parent_node
    if self.parent.nil?
      errors.add(:parent_id, 'is missing/invalid.')
      return false
    end

    if !(self.parent.user_node?)
      errors.add(:parent_id, 'has an invalid type.')
      return false
    end
  end
end
