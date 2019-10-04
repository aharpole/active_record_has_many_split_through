# frozen_string_literal: true

module ActiveRecord
  module Associations
    class SplitAssociationScope < AssociationScope
      class OrderedScope < DelegateClass(ActiveRecord::Relation)
        TOO_MANY_RECORDS = 5000

        def initialize(scope, key, ids)
          @ids = ids.uniq
          @key = key
          super(scope)
        end

        def to_a
          records = super

          if records.length > TOO_MANY_RECORDS
            warn("You've requested to order #{records.length} in memory. This may have an impact on the performance of this query. Use with caution.")
          end

          records_by_id = records.group_by do |record|
            record[@key]
          end

          records = @ids.flat_map { |id| records_by_id[id] }
          records.compact!
          records
        end
      end

      def scope(association)
        # source of the through reflection
        source_reflection = association.reflection
        owner = association.owner

        # remove all previously set scopes of passed in association
        scope = association.klass.unscoped

        chain = get_chain(source_reflection, association, scope.alias_tracker)

        reverse_chain = chain.reverse
        first_reflection = reverse_chain.shift
        first_join_ids = [owner.id]

        initial_values = [first_reflection, false, first_join_ids]

        last_reflection, last_ordered, last_join_ids = reverse_chain.inject(initial_values) do |(reflection, ordered, join_ids), next_reflection|
          key = reflection.join_keys.key

          # "WHERE key IN ()" is invalid SQL and will happen if join_ids is empty,
          # so we gotta catch it here in ruby
          record_ids = if join_ids.present?
            records = add_reflection_constraints(reflection, key, join_ids, owner, ordered)

            foreign_key = next_reflection.join_keys.foreign_key
            records.pluck(foreign_key)
          else
            []
          end

          records_ordered = records && records.order_values.any?

          [next_reflection, records_ordered, record_ids]
        end

        if last_join_ids.present?
          key = last_reflection.join_keys.key

          add_reflection_constraints(last_reflection, key, last_join_ids, owner, last_ordered)
        else
          last_reflection.klass.none
        end
      end

      private
        def select_reflection_constraints(reflection, scope_chain_item, owner, scope)
          item = eval_scope(reflection, scope_chain_item, owner)
          scope.unscope!(*item.unscope_values)
          scope.where_clause += item.where_clause
          scope.order_values = item.order_values | scope.order_values
          scope
        end

        def add_reflection_constraints(reflection, key, join_ids, owner, ordered)
          scope = reflection.klass.where(key => join_ids)
          scope = reflection.constraints.inject(scope) do |memo, scope_chain_item|
            select_reflection_constraints(reflection, scope_chain_item, owner, memo)
          end

          if reflection.type
            polymorphic_type = transform_value(owner.class.polymorphic_name)
            scope = apply_scope(scope, reflection.aliased_table, reflection.type, polymorphic_type)
          end

          if ordered
            OrderedScope.new(scope, key, join_ids)
          else
            scope
          end
        end
    end

    # = Active Record Has Many Through Association
    class HasManySplitThroughAssociation < HasManyThroughAssociation #:nodoc:
      def scope
        SplitAssociationScope.create.scope(self)
      end

      def find_target
        scope.to_a
      end
    end
  end
end
