# frozen_string_literal: true

module ActiveRecord::Associations::Builder # :nodoc:
  class HasManySplitThrough < HasMany #:nodoc:
    def self.valid_options(options)
      super + [:split, :batch_size]
    end
  end
end
