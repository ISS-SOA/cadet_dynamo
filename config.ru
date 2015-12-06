Dir.glob('./{config,models,services,controllers}/init.rb').each do |file|
  require file
end

run CadetDynamo
