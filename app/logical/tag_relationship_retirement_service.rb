module TagRelationshipRetirementService
  THRESHOLD = 3.year
  SMALL_THRESHOLD = 1.year
  COUNT_THRESHOLD = 10

  extend self

  def dry_run
    [TagAlias, TagImplication].each do |model|
      each_candidate(model) do |rel|
        puts "#{rel.relationship} #{rel.antecedent_name} -> #{rel.consequent_name} retired"
      end
    end
  end

  def find_and_retire!
    messages = []

    [TagAlias, TagImplication].each do |model|
      each_candidate(model) do |rel|
        service = new(rel)
        messages << service.check_and_update(messages)
      end
    end

    messages
  end

  def each_candidate(model)
    model.active.where("created_at < ?", THRESHOLD.ago).find_each do |rel|
      if is_unused?(rel.consequent_name)
        yield(rel)
      end
    end

    model.active.where("created_at < ?", SMALL_THRESHOLD.ago).find_each do |rel|
      if is_underused?(rel.consequent_name)
        yield(rel)
      end
    end
  end

  def is_underused?(name)
    (Tag.find_by_name(name).try(:post_count) || 0) < COUNT_THRESHOLD
  end

  def is_unused?(name)
    return !Post.tag_match("status:any #{name}").where("created_at > ?", THRESHOLD.ago).exists?
  end
end
