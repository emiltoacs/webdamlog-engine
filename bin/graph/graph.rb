# #!/usr/bin/env ruby

# snippet used to allow to load wlbud by other means that using gems
begin
  require '../lib/wlbud'
rescue LoadError
  require 'rubygems'
  require 'wlbud'
end


STR1 = <<EOF
peer p1=localhost:11110;
collection ext persistent local1@p1(atom1*);
collection ext persistent local2@p1(atom1*);
collection ext persistent local3@p1(atom1*);
collection int join1@p1(atom1*);
collection int join2@p1(atom1*);
fact local1@p1(11);
fact local1@p1(12);
fact local1@p1(13);
fact local1@p1(14);
fact local2@p1(21);
fact local2@p1(22);
fact local2@p1(23);
fact local2@p1(24);
fact local2@p1(17);
fact local3@p1(31);
fact local3@p1(32);
fact local3@p1(33);
fact local3@p1(34);
fact local3@p1(34);
fact local4@p1(41);
fact local4@p1(42);
fact local4@p1(43);
fact local4@p1(44);
rule join1@p1($x):- local1@p1($x),local2@p1($x);
rule join1@p1($x):- local3@p1($x);
end
EOF

File.open("test_pg","w"){ |file| file.write STR1 }
@prog = WLBud::WL.new('p1', "test_pg",
  :ip=>"localhost",:port=>"13245",
  :debug=>true,:debug2 =>true,
  :dump_rewrite=>true,:dump_ast=>false,:print_wiring=>true,
  :tag => "test_pg", :trace => true,
  :metrics => true, :mesure => false)
@prog.run_bg
@prog.sync_do do
  @prog.chan << ["localhost:12340",
    ["p0", "0",
      {"rules"=>[],
        "facts"=>{ "local1_at_p1"=>[["21"], ["22"], ["23"]] },
        "declarations"=>[]
      }]]
end
@prog.sync_do do
  @prog.chan << ["localhost:12340",
    ["p0", "0",
      {"rules"=>["rule join2@p1($x):- join1@p1($x), local4@p1($x);"],
        "facts"=>{"local4_at_p1"=>[["21"]]},
        "declarations"=>["collection ext persistent local4@p1(atom1*);"]
      }]]
end
@prog.sync_do do
  @prog.chan << ["localhost:12340",
    ["p0", "0",
      {"rules"=>[],
        "facts"=>{"local4_at_p1"=>[["22"],]},
        "declarations"=>[]
      }]]
end

# #File.delete("test_pg")

