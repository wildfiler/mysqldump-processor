Rules.define do
  table :users do
    sequence(:login) { |n| "user#{n}" }
    password nil
  end

  table :something do
    sequence(:id) { |n| n }
    foo 1
    bar "test"
    baz { |old_value| "#{old_value[0..5]}***" }
  end

  tables :users, :managers do
    some_token nil
    sequence(:name) { |n, old_value| "name #{old_value[0]}#{n}" }
  end
end
