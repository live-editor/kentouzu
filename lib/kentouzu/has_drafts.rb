module Kentouzu
  module Model
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def has_drafts options = {}
        send :include, InstanceMethods

        class_attribute :draft_association_name
        self.draft_association_name = options[:draft] || :draft

        attr_accessor self.draft_association_name

        class_attribute :draft_class_name
        self.draft_class_name = options[:class_name] || 'Draft'

        class_attribute :ignore
        self.ignore = ([options[:ignore]].flatten.compact || []).map &:to_s

        class_attribute :if_condition
        self.if_condition = options[:if]

        class_attribute :unless_condition
        self.unless_condition = options[:unless]

        class_attribute :skip
        self.skip = ([options[:skip]].flatten.compact || []).map &:to_s

        class_attribute :only
        self.only = ([options[:only]].flatten.compact || []).map &:to_s

        class_attribute :drafts_enabled_for_model
        self.drafts_enabled_for_model = true

        class_attribute :drafts_association_name
        self.drafts_association_name = options[:draft] || :draft

        has_many self.drafts_association_name,
                 :class_name => draft_class_name,
                 :as         => :item,
                 :order      => "#{Kentouzu.timestamp_field} ASC, #{self.draft_class_name.constantize.primary_key} ASC",
                 :dependent  => :destroy

        def drafts_off
          self.drafts_enabled_for_model = false
        end

        def drafts_on
          self.drafts_enabled_for_model = true
        end
      end
    end

    module InstanceMethods
      def self.included(base)
        default_save = base.instance_method(:save)

        base.send :define_method, :save do
          if switched_on? && save_draft?
            puts "calling new save"

            draft = Draft.new(:item_type => self.class.to_s, :item_id => self.id, :event => self.persisted? ? "update" : "create", :source_type => Drafts.source.present? ? Drafts.source.class.to_s : nil, :source_id => Drafts.source.present? ? Drafts.source.id : nil, :object => self.to_yaml)

            draft.save
          else
            puts "calling default save"

            puts self.inspect

            default_save.bind(self).()
          end
        end
      end

      #def live?
      #  source_draft.nil?
      #end

      def draft_at timestamp, reify_options = {}
        v = send(self.class.versions_association_name).following(timestamp).first
        v ? v.reify(reify_options) : self
      end

      def without_drafts method = nil
        drafts_were_enabled = self.drafts_enabled_for_model

        puts "drafts_were_enabled #{drafts_were_enabled}"

        self.class.drafts_off

        puts "self.drafts_enabled_for_model #{self.drafts_enabled_for_model}"

        puts method

        method ? method.to_proc.call(self) : yield
      ensure
        self.class.drafts_on if drafts_were_enabled
      end

      private

      #def draft_class
      #  draft_class_name.constantize
      #end
      #
      #def source_draft
      #  send self.class.draft_association_name
      #end

      def switched_on?
        Kentouzu.enabled? && Kentouzu.enabled_for_controller? && self.class.drafts_enabled_for_model
      end

      def save_draft?
        (if_condition.blank? || if_condition.call(self)) && !unless_condition.try(:call, self)
      end
    end
  end
end