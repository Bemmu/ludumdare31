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

		var pts = [];

		var totalPoints = 0;

		function addTotalPoints(pts) {
			totalPoints += pts;
		}

		function awardPoints(amount, x) {
			if (amount > 0) {
				new GoodSound().play();
			} else {
				new BadSound().play();
			}

			var f = new FloatingPoints();
			f.amount = amount;
			f.ySpeed = -2.0;
			f.x = x;
			f.y = 100;
			pts.push(f);
		}

		function drawFloatingPoints() {

			var matrix;

			for each (var p in pts) {
				var tf = new TextField();
				var format = new TextFormat();
				format.size = 20;
				format.color = 0xff00ff00;
				tf.defaultTextFormat = format;
				matrix = new Matrix();
				matrix.translate(p.x + 5, p.y);
				tf.text = "+" + p.amount;
				frontbufferBitmapData.draw(tf, matrix);
			}

			var t = new TextField();
			t.text = "" + totalPoints + " points";
			matrix = new Matrix();
			matrix.translate(200, 182);
			frontbufferBitmapData.draw(t, matrix);
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

		var gameOver = false;

		function fail() {
			gameOver = true;
			new BadSound().play();

			var failField = new TextField();
			failField.x = 130;
			failField.y = 15;
			failField.width = 180;
			failField.height = 500;
			failField.multiline = true;
			failField.text = "You forgot " + guests[0].text + "'s name!\nHe got angry, your party failed.\nReload page to play again.";
			addChild(failField);

			removeChild(input);
		}

		function tick() {
			if (gameOver) return;
			ticks += 1;
			if (inOpeningScreen) return;

			var newPts = [];
			for each (var p in pts) {
				p.y += p.ySpeed;
				p.ySpeed *= 0.94;

				if (Math.abs(p.ySpeed) < 0.1) {
					addTotalPoints(p.amount);
				} else {
					newPts.push(p);
				}
			}
			pts = newPts;

			var now = getTimer();
			var elapsedSeconds = (now - past)*0.001;
			past = now;

			if ((ticks % 400) == 0) {
				speed += 0.1;
			}

			if (guests.length === 0 || minPos() > guestSpacing) {
				spawnGuest();
			}

			for each (var guest in guests) {
				guest.tick(speed);
			}

			if (guests[0].pos > 280 && !guests[0].done) {
				fail();
				return;
			}

			if (guests[0].pos > 300) {
				guests.shift();
			}

//			fail();
		}

		var bg:BitmapData;
		var spriteHeight = 40;

		function drawBackground() {
			frontbufferBitmapData.copyPixels(
				bg,
				new Rectangle(0, 0, bg.width, 180),
				new Point(0, 0)
			);
			frontbufferBitmapData.copyPixels(
				bg,
				new Rectangle(0, 360, bg.width, 20),
				new Point(0, 180)
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
			if (gameOver) {
				copyPixels(80, 182 + spriteHeight, 40, 40, x - 3 + Math.sin(cycleOffset + ticks*0.1)*1, y - 26 + 2);
			} else {
				copyPixels(80, 182, 40, 40, x - 3 + Math.sin(cycleOffset + ticks*0.1)*1, y - 26 + Math.sin(cycleOffset + ticks*0.1 + Math.PI/2)*1 + 2);
			}

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

		function isSomeoneNearHandshakers() {
			for each (var g in guests) {
				if (Math.abs(g.pos - 260) < 50) {
					return true;
				}
			}
			return false;
		}

		function drawHandShakingCouple() {
			// brah
			copyPixels(120, 182 + 40 * (Math.floor(ticks/20)%2), 40, 40, 260, 123);

			// gal
			copyPixels(120 + 40, 182 + 40 * (Math.floor(ticks/18)%2), 40, 40, 280, 123);
		}

		var openBitmapData;

		function drawOpeningScreen() {
			var i;
			for (i = 0; i < 320; i++) {
				frontbufferBitmapData.copyPixels(
					openBitmapData,
					new Rectangle(0, i, 320, 1),
					new Point(Math.sin(ticks * 0.2 + i*0.02) * 10, i)
				);
			}
			for (i = 0; i < 320; i++) {
				frontbufferBitmapData.copyPixels(
					openBitmapData,
					new Rectangle(i, 0, 1, 132),
					new Point(i, Math.sin(i * 0.01 + ticks * 0.25 + Math.cos(i * 0.02 + ticks * 0.012)) * 3)
				);
			}
		}

		function openingScreenClosed() {
			ticks = 0;
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

				for each (var guest in guests) {
					if (guest.done) continue;
					if (guest.text == input.text) {
						awardPoints(Math.floor(10 + speed*10), Math.max(DOOR_CENTER, guest.pos));
						guest.done = true;
						guest.text = 0;
					}
				}

				input.text = "";
			}
		}

		var wordChoices = [
			"pekka",
			"matti",
			"teppo",
			"sauli",
			"marko",
			"mika",
			"bemmu",
			"kari",
			"matias",
			"john",
			"jack",
			"kevin",
			"bob",
			"rauli",
			"michael",
			"sacha",
			"tomi",
			"jorma"
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

			// Try until get a word that is not already in guest list
			var word = randomWord();
			var c = 0;
			while (true) {
				c++;
				var wasNew = true;
				for each (var g in guests) {
					if (g.text == word) {
						wasNew = false;
						break;
					}
				}
				if (wasNew) {
					break;
				}
				if (c > 1000) {
					trace("got stuck!");
					return;
				}
			}

			guest.text = word;
			guests.push(guest);
		}

		private function mouseClick(evt) {
			if (inOpeningScreen) {
				inOpeningScreen = false;
				openingScreenClosed();
			}
		}

		public function Game() {
			openBitmapData = new Open();
			spawnGuest();

			bg = new Bg();
			past = getTimer();

			frontbufferBitmapData = new BitmapData(320, 200, true, 0);
			addChild(new Bitmap(frontbufferBitmapData));
			stage.addEventListener(MouseEvent.CLICK, mouseClick); 
			addEventListener(Event.ENTER_FRAME, refresh);

			words = new TextField();
			words.text = "";
			words.x = 130;
			words.y = 15;
			addChild(words);

//			inOpeningScreen = false;
//			openingScreenClosed();
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

class FloatingPoints {
	var amount = 0;
	var x = 280;
	var y = 100;
	var ySpeed = -0.1;
}
