require 'yaml'
require 'r10k/puppetfile'

reqs = YAML.load_file(__dir__ + '/pf_validation.yaml')

pf_root = ARGV[0] || Dir.pwd

puppetfile = R10K::Puppetfile.new(pf_root)
puppetfile.load!

results = []
issues = 0

mods = puppetfile.modules.collect do |mod|
  mod.name
end

reqs.keys.each do |req|
  if ! mods.include? req
    results << "Module [#{req}] must be in the Puppetfile but cannot be found"
    issues = issues +1
  end
end

puppetfile.modules.each do |mod|
  details = reqs[mod.name]
  if details
    if details['source']
      if mod.is_a?(R10K::Module::Git)
        if mod.instance_variable_get(:@remote) == details['source']
          results << "Module [#{mod.name}] has valid source"
        else
          results << "Module [#{mod.name}] does not have a valid source, should be #{details['source']}"
          issues = issues+1
        end
      elsif mod.is_a?(R10K::Module::Forge)
        issues = issues+1
        results << "Module [#{mod.name}] is Forge module but has a source in the validation requirements, sure this shouldn't be a git module?"
      end
    end

    if details['refs']
      short_ref = mod.desired_ref[0..6]
      if details['refs'].include? short_ref
        results << "Module [#{mod.name}] has a valid ref"
      else
        results << "Module [#{mod.name}] does not have a valid ref"
        issues = issues+1
      end
    end
  end
end

puts results.join("\n")

if issues > 0
  exit 1
else
  exit 0
end
