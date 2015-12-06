Dir.glob('./{config,model,controller}/init.rb').each { |file| require file}
run CadetDynamo
