package;


import flash.display.Sprite;
import Flow;
import promhx.Stream;


class Main extends Sprite {
	
	
	public function new () {
		super ();
		var foob = Flow.on({x:100, y:1}, "
		        <flash.text.TextField text='helloworld' :x='x' .y='4'/>
		        ");
		var t = new haxe.Timer(20);
		var count = 0;
		t.run = function(){
		    foob.state.x.resolve(count);
		    count+=1;
        }
		flash.Lib.current.addChild(foob);
	}
}