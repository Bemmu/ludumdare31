package {
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	import flash.text.*;

	public class Game extends Sprite {
		var frontbufferBitmapData;
		var inOpeningScreen = true;

		var legCycle = 0;
		var speed = 0.1;
		var guestSpacing = 50;

		var past;
		var ticks = 0;
		var guests = [];

		var floatingPoints = 0;
		var floatX = 280;
		var floatY = 100;
		var floatYSpeed = -0.1;
		var totalPoints = 0;

		function addTotalPoints(pts) {
			totalPoints += pts;
		}

		function awardPoints(pts) {
			if (pts > 0) {
				new GoodSound().play();
			} else {
				new BadSound().play();
			}

			floatingPoints = pts;
			floatYSpeed = -2.0;
			floatY = 100;
		}

		function drawFloatingPoints() {
			if (floatingPoints === 0) {
				return;
			}

			var tf = new TextField();
			var format = new TextFormat();
			format.size = 20;
			tf.setTextFormat(format);
			var matrix = new Matrix();
			matrix.translate(floatX, floatY);
			tf.text = "" + floatingPoints;
			frontbufferBitmapData.draw(tf, matrix);

			floatY += floatYSpeed;
			floatYSpeed *= 0.94;
		}

		function minPos() {
			var m = -1;
			for each (var guest in guests) {
				if (m == -1 || guest.pos < m) {
					m = guest.pos;
				}
			}
			return m;
		}

		function tick() {
			if (inOpeningScreen) return;

			if (Math.abs(floatYSpeed) < 0.1) {
				addTotalPoints(floatingPoints);
				floatingPoints = 0;
			}

			var now = getTimer();
			var elapsedSeconds = (now - past)*0.001;
			ticks += 1;
			past = now;

			if ((ticks % 1000) == 0) {
				speed += 0.2;
			}

			if (guests.length === 0 || minPos() > guestSpacing) {
				spawnGuest();
			}

			for each (var guest in guests) {
				guest.tick(speed);
			}
		}

		var bg:BitmapData;
		var spriteHeight = 40;

		function drawBackground() {
			frontbufferBitmapData.copyPixels(
				bg,
				new Rectangle(0, 0, bg.width, 180),
				new Point(0, 0)
			);
		}

		function copyPixels(sx, sy, sw, sh, tx, ty) {
			frontbufferBitmapData.copyPixels(
				bg,
				new Rectangle(sx, sy, sw, sh),
				new Point(tx, ty),
				null, null, true
			);
		}

		function drawCharacter(x, y, cycleOffset, done, text) {
			// legs
			copyPixels(0, 182 + spriteHeight * (Math.floor(ticks/10) % 3), 40, 40, x + Math.sin(cycleOffset + ticks*0.1 + Math.PI)*4, y);
			copyPixels(0, 182 + spriteHeight * ((2 + Math.floor(ticks/10)) % 3), 40, 40, x + Math.sin(cycleOffset + ticks*0.1)*4, y);

			// Torso
			copyPixels(40, 182, 40, 40, x - 1 + Math.sin(cycleOffset + ticks*0.1)*1, y - 12 + Math.sin(cycleOffset + ticks*0.1 + Math.PI)*1 + 1);

			// head
			copyPixels(80, 182, 40, 40, x - 3 + Math.sin(cycleOffset + ticks*0.1)*1, y - 26 + Math.sin(cycleOffset + ticks*0.1 + Math.PI/2)*1 + 2);

			// text that the player has to type
			if (!done) {
				var tf = new TextField();
				var matrix = new Matrix();
				matrix.translate(x, y + 24);
				tf.text = text;
				frontbufferBitmapData.draw(tf, matrix);
			}
		}

		var DOOR_CENTER = 30;

		function drawCharacters() {
			for each (var guest in guests) {
				if (guest.pos < DOOR_CENTER) {
					drawCharacter(DOOR_CENTER, 140 + guest.pos - DOOR_CENTER, guest.cycleOffset, guest.done, guest.text);
				} else {
					drawCharacter(guest.pos, 140, guest.cycleOffset, guest.done, guest.text);
				}
			}
		}

		function drawHandShakingCouple() {
			// brah
			copyPixels(120, 182 + 40 * (Math.floor(ticks/20)%2), 40, 40, 260, 123);

			// gal
			copyPixels(120 + 40, 182 + 40 * (Math.floor(ticks/18)%2), 40, 40, 280, 123);
		}

		var openBitmapData;

		function drawOpeningScreen() {
			for (var i = 0; i < 320; i++) {
				frontbufferBitmapData.copyPixels(
					openBitmapData,
					new Rectangle(0, 0, 320, 200),
					new Point(0, 0)
				);
			}
		}

		function render() {
			if (inOpeningScreen) {
				drawOpeningScreen();
			} else {
				drawBackground();
				drawHandShakingCouple();
				drawCharacters();
				drawFloatingPoints();
			}
		}

		function refresh(evt) {
			var start = getTimer();			
			render(); 
			var renderTime = getTimer();
			tick();
//			trace(renderTime - start, 'ms / render()', getTimer() - renderTime, 'ms / tick()');
		}

		var input:TextField;
		var words:TextField;

		function didInput(event:KeyboardEvent){	
			if (event.charCode == 13) {
				awardPoints(10);

				for each (var guest in guests) {
					if (guest.done) continue;
					if (guest.text == input.text) {
						guest.done = true;
					}
				}

				input.text = "";
				guests.shift();
			}
		}

		var wordChoices = [
			"foobar",
			"foobar23",
			"fooba12r",
			"foob12ar",
		];

		private function randomWord() {
			var i = Math.floor(Math.random() * wordChoices.length);
			return wordChoices[i];
		}

		private function spawnGuest() {
			var guest = new Guest();
			guest.pos = 0;
			guest.cycleOffset = Math.random() * Math.PI*2;
			guest.done = false;
			guest.text = randomWord();
			guests.push(guest);
		}

		public function Game() {
			openBitmapData = new Open();
			spawnGuest();

			bg = new Bg();
			past = getTimer();

			frontbufferBitmapData = new BitmapData(320, 200, true, 0);
			addChild(new Bitmap(frontbufferBitmapData));
			addEventListener(Event.ENTER_FRAME, refresh);

			words = new TextField();
			words.text = "";
			words.x = 130;
			words.y = 15;
			addChild(words);

			var format = new TextFormat();
			format.size = 20;

			input = new TextField();
			input.text = "";
			addChild(input);

			input.y = 20;
			input.x = 130;
			input.width = 156;
			input.height = 40;
			input.setTextFormat(format);
			input.type = TextFieldType.INPUT;
			stage.focus = input;

			addEventListener(KeyboardEvent.KEY_DOWN, didInput);
		}
	}
}

class Guest {
	public var cycleOffset;
	public var pos;
	public var done = false;
	public var text;

	public function tick(speed) {
		pos += speed;
	}
}
