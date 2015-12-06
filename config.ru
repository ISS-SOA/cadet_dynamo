Dir.glob('./{config,model,services,controller}/init.rb').each { |file| require file}
run CadetDynamo
