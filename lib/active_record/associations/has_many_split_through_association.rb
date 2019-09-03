# frozen_string_literal: true

module ActiveRecord
  module Associations
    class SplitAssociationScope < AssociationScope
      def scope(association, options)
        # source of the through reflection
        source_reflection = association.reflection
        # remove all previously set scopes of passed in association
        scope = association.klass.unscoped

        chain = get_chain(source_reflection, association, scope.alias_tracker)

        reverse_chain = chain.reverse
        first_reflection = reverse_chain.shift
        first_join_ids = [association.owner.id]

        initial_values = [first_reflection, first_join_ids]

        last_reflection, last_join_ids = reverse_chain.inject(initial_values) do |(reflection, join_ids), next_reflection|
          # "WHERE key IN ()" is invalid SQL and will happen if join_ids is empty,
          # so we gotta catch it here in ruby
          record_ids = if join_ids.present?
            if options[:batch_size].present?
              get_ids_in_batches(reflection, join_ids, next_reflection, options[:batch_size])
            else
              get_ids(reflection, join_ids, next_reflection)
            end
          else
            [].tap { |ids| p ids }
          end

          [next_reflection, record_ids]
        end

        if last_join_ids.present?
          key = last_reflection.join_keys.key
          where_sql = ActiveRecord::Base.sanitize_sql(["#{key} IN (?)", last_join_ids])
          last_reflection.klass.where(where_sql).tap { |rel| p [rel, rel.count] }
        else
          last_reflection.klass.none.tap { |rel| p [rel, rel.count] }
        end
      end

      def get_ids(reflection, join_ids, next_reflection)
        where_sql = ActiveRecord::Base.sanitize_sql(["#{reflection.join_keys.key} IN (?)", join_ids])
        records = reflection.klass.where(where_sql)
        foreign_key = next_reflection.join_keys.foreign_key
        records.pluck(foreign_key).tap { |ids| p ids }
      end

      def get_ids_in_batches(reflection, join_ids, next_reflection, batch_size)
        where_sql = ActiveRecord::Base.sanitize_sql(["#{reflection.join_keys.key} IN (?)", join_ids])

        ids = []

        reflection.klass.where(where_sql).in_batches(of: batch_size).each do |refl|
          p [:batch_refl, refl]
          foreign_key = next_reflection.join_keys.foreign_key
          ids.push(refl.pluck(foreign_key).tap { |rids| p rids })
        end

        ids
      end
    end

    # = Active Record Has Many Through Association
    class HasManySplitThroughAssociation < HasManyThroughAssociation #:nodoc:
      def scope
        SplitAssociationScope.create.scope(self, options)
      end

      def find_target
        scope
      end
    end
  end
end
