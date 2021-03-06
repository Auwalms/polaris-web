<browser>

	<div class="paneHeader">
		<h2>{ title }</h2>
		<div if={ tab == "random" } class="more noselect" onclick={ onClickMoreRandom }><i class="material-icons md-18">refresh</i><span>More</span></div>
		<breadcrumbs if={ path != null }/>
	</div>

	<div class="paneContent">
		<ul if={ viewMode == "explorer" } class="explorerView">
			<div class="viewActions">
				<div class="header">{ header }</div>
				<button onclick={ onQueueAll } class="small">Queue All</button><button if={ tab == "playlist" } class="danger small" onclick={ onDeletePlaylist }>Delete</button>
			</div>
			<li draggable="true" each={ items } onclick={ onClickItem } ondragstart={ onDragItemStart }>
				<div if={ variant == "Directory" } class="directory">{ fields.name }</div>
				<div if={ variant == "Song" } class="song">{ fields.artist } - { fields.track_number }. { fields.title }</div>
			</li>
		</ul>

		<div if={ viewMode == "discography" } class="discographyView">
			<div class="viewActions" if={ path }>
				<div class="header">{ header }</div>
				<button onclick={ onQueueAll } class="small">Queue All</button>
			</div>
			<ul>
				<li class="album" draggable="true" each={ items } onclick={ onClickItem } ondragstart={ onDragItemStart }>
					<div class="cover">
						<div class="coverCanvas">
							<img if={ fields.artwork } src="{ fields.artworkURL }"/>
						</div>
					</div>
					<div class="details">
						<div class="title">{ fields.album }</div>
						<div if={ path == null } class="artist">{ fields.artist }</div>
						<div class="year">{ fields.year }</div>
					</div>
				</li>
			</ul>
		</div>

		<div if={ viewMode == "album" } class="albumView">
			<div class="viewActions">
				<div class="header">{ header }</div>
				<div class="subHeader">{ subHeader }</div>
				<button onclick={ onQueueAll } class="small">Queue All</button>
			</div>
			<div class="details">
				<img src="{ artworkURL }" draggable="true" onclick={ onClickAlbum } ondragstart={ onDragAlbumStart } />
				<div class="trackList">
					<ul>
						<li each={ items } >
							<div class="discNumber" if="{ items.length > 1 }">Disc { discNumber }</div>
							<ol class="discContent">
								<li value={ fields.track_number } class="song" draggable="true" each={ songs } onclick={ onClickItem } ondragstart={ onDragItemStart }>
									{ fields.title }
									<span class="trackArtist" if={ fields.artist && fields.album_artist && fields.artist != fields.album_artist }>
										({ fields.artist })
									</span>
								</li>
							</ol>
						</li>
					</ul>
				</div>
			</div>
		</div>
	</div>

	<script>

		var self = this;

		reset() {
			this.items = [];
			this.artworkURL = null;
			this.header = null;
			this.subHeader = null;
			this.playlistName = null;
			this.path = null;
			this.title = "";
			this.viewMode = "explorer"; // explorer/discography/album
		}

		var r = route.create();
		r("", browse);
		r("browse..", browse);
		r("playlist..", playlist);
		r("random", random);
		r("recent", recent);
		this.on('mount', function() {
			route.exec();
		});

		this.on('unmount', function() {
			r.stop();
		});

		getViewMode(items) {
			var onlySongs = true;
			var allHaveAlbums = true;
			var hasAnyPicture = false;

			for (var i = 0; i < items.length; i++) {
				var item = items[i];
				if (!item.fields.album) {
					allHaveAlbums = false;
				}

				if (item.fields.artwork) {
					item.fields.artworkURL = "api/serve/" + encodeURIComponent(item.fields.artwork);
					hasAnyPicture = true;
				}

				if (item.variant == "Song") {
					item.fields.url = "api/serve/" + encodeURIComponent(item.fields.path);
					this.header = this.header || item.fields.album;
					this.artworkURL = this.artworkURL || item.fields.artworkURL;
					this.subHeader = this.subHeader || item.fields.album_artist || item.fields.artist;
				} else {
					onlySongs = false;
					var slices = item.fields.path.replace(/\\/g, "/").split("/");
					slices = slices.filter(function(s) { return s.length > 0; });
					item.fields.name = slices[slices.length-1];
				}
			}

			this.header = this.header || this.getPathTail(this.path);

			if (this.tab != "playlist") {
				if (hasAnyPicture && onlySongs && items.length > 0) {
					return "album";
				} else if (hasAnyPicture && allHaveAlbums) {
					return "discography";
				}
			}

			return "explorer";
		}

		getPathTail(path) {
			if (!path) {
				return "All Music";
			}
			path = path.replace(/\\/g, "/");
			var slices = path.split("/");
			slices = slices.filter(function(s) { return s.length > 0; });
			return slices[slices.length - 1] || "";
		}

		splitAlbumByDisc(items) {
			var discs = [];
			for (var i = 0; i < items.length; i++) {
				var discNumber = items[i].fields.disc_number || 1;
				var disc = discs.find(function(d){ return d.discNumber == discNumber });
				if (disc == undefined) {
					disc = {
						discNumber: discNumber,
						songs: [],
					};
					discs.push(disc);
				}
				disc.songs.push(items[i]);
			}
			discs.sort(function(a,b){ return a.discNumber - b.discNumber; });
			return discs;
		}

		displayItems(items) {
			this.viewMode = this.getViewMode(items);
			if (this.viewMode == "album") {
				this.items = this.splitAlbumByDisc(items);
			} else {
				this.items = items;
			}
			this.update();
		}

		function random() {
			fetch("api/random/", { credentials: "same-origin" })
			.then(function(res) { return res.json(); })
			.then(function(data) {
				this.reset();
				for (var i = 0; i < data.length; i++) {
					data[i] = {
						variant: "Directory",
						fields: data[i],
					}
				}
				this.tab = "random";
				this.title = "Random Albums";
				this.displayItems(data);
			}.bind(self));
		}

		function recent() {
			fetch("api/recent/", { credentials: "same-origin" })
			.then(function(res) { return res.json(); })
			.then(function(data) {
				this.reset();
				for (var i = 0; i < data.length; i++) {
					data[i] = {
						variant: "Directory",
						fields: data[i],
					}
				}
				this.tab = "recent";
				this.title = "Recently Added";
				this.displayItems(data);
			}.bind(self));
		}

		function browse() {
			var matchPath = /^.*#browse\/?(.*)$/;
			var matches = window.location.href.match(matchPath);
			var path = matches ? matches[1] : "";
			path = decodeURIComponent(path);

			fetch("api/browse/" + path, { credentials: "same-origin" })
			.then(function(res) { return res.json(); })
			.then(function(data) {
				this.reset();
				this.path = path;
				for (var i = 0; i < data.length; i++) {
					data[i].fields = data[i].Directory || data[i].Song;
					data[i].variant = data[i].Directory ? "Directory" : "Song";
				}
				this.tab = "browse";
				this.title = "Music Collection";
				this.displayItems(data);
				this.tags.breadcrumbs.setCurrentPath(path);
			}.bind(self));
		}

		function playlist() {
			var matchPath = /^.*#playlist\/?(.*)$/;
			var matches = window.location.href.match(matchPath);
			var playlistName = matches ? matches[1] : "";
			playlistName = decodeURIComponent(playlistName);

			fetch("api/playlist/read/" + playlistName, { credentials: "same-origin" })
			.then(function(res) { return res.json(); })
			.then(function(data) {
				this.reset();
				for (var i = 0; i < data.length; i++) {
					var fields = data[i];
					data[i] = { fields: fields, variant: "Song" };
				}
				this.tab = "playlist";
				this.title = "Playlists";
				this.playlistName = playlistName;
				this.header = playlistName;
				this.displayItems(data);
			}.bind(self));
		}

		onClickMoreRandom(e) {
			e.preventDefault();
			route.exec();
		}

		onClickItem(e) {
			var variant = e.item.variant;
			if (variant == "Directory") {
				route("browse/" + e.item.fields.path);
			} else if (variant == "Song") {
				eventBus.trigger("browser:queueTrack", e.item.fields);
			}
		}

		onQueueAll(e) {
			if (this.tab == "playlist") {
				eventBus.trigger("browser:queueTracks", this.items.map(function(i){ return i.fields; }));
				eventBus.trigger("browser:queuedPlaylist", this.playlistName);
			} else {
				eventBus.trigger("browser:queueDirectory", this.path);
			}
		}

		onDragItemStart(e) {
			e.dataTransfer.setData("text/json", JSON.stringify(e.item));
		}

		onDragAlbumStart(e) {
			var directoryItem = {
				variant: "Directory",
				fields: {
					path: this.path,
				},
			};
			e.dataTransfer.setData("text/json", JSON.stringify(directoryItem));
		}

		onClickAlbum(e) {
			eventBus.trigger("browser:queueDirectory", this.path);
		}

		onDeletePlaylist(e) {
			fetch("api/playlist/" + this.playlistName,
				{	method: "DELETE"
				,	credentials: "same-origin"
				}
			)
			.then(function(res) {
				route("playlists/");
			});
		}
	</script>

	<style>

		.more {
			cursor: pointer;
			height: 20px;
		}

		.more span {
			padding-left: 4px;
			font-size: 0.875rem;
			vertical-align: top;
		}

		.paneContent {
			padding-top: 50px;
		}

		.viewActions {
			margin-bottom: 40px;
		}

		.viewActions .header {
			line-height: 1;
			margin-bottom: 5px;
			font-size: 1.25rem;
			font-family: "Montserrat", "sans-serif";
		}

		.viewActions .subHeader {
			line-height: 1;
			font-size: 1.25rem;
			margin-bottom: 5px;
			color: #AAA;
		}

		.viewActions button {
			display: inline;
		}

		.explorerView, .albumView {
			margin-bottom: 50px;
		}

		/*Explorer view*/
		.explorerView .explorerActions {
			margin-bottom: 20px;
		}

		.explorerView .directory:before {
			content: "🗀";
			margin-right: 5px;
		}

		.explorerView .directory, .explorerView .song {
			cursor: default;
			max-width: 100%;
			white-space: nowrap;
			overflow: hidden;
			text-overflow: ellipsis;
		}

		/*Discography view*/
		.discographyView ul {
			display: flex;
			flex-wrap: wrap;
			justify-content: flex-start;
		}

		.discographyView .album {
			font-size: 0;
			margin-bottom: 20px;
			cursor: default;
			width: 23.5%;
			margin-left: 1%;
			margin-right: 1%;
		}

		.discographyView .album:nth-child(4n+1) { margin-left: 0; }
		.discographyView .album:nth-child(4n) { margin-right: 0; }

		.discographyView .cover {
			width: 100%;
			position: relative;
		}

		.discographyView .cover:after {
			/*Hack to make this element stay square when its width changes*/
			content: "";
			display: block;
			padding-bottom: 100%;
		}

		.discographyView .coverCanvas {
			position: absolute;
			width: 100%;
			height: 100%;
		}

		.discographyView img {
			width: 100%;
			height: 100%;
			border-radius: 5px;
		}

		.discographyView .details {
			padding: 10px 0;
			width: 100%;
		}

		.discographyView .details .title {
			font-family: "Montserrat", "sans-serif";
			overflow: hidden;
			text-overflow: ellipsis;
			padding-right: 10px;
			font-size: 1rem;
		}

		.discographyView .details .artist {
			margin-bottom: -5px;
			overflow: hidden;
			text-overflow: ellipsis;
			padding-right: 10px;
			font-size: 0.875rem;
		}

		.discographyView .details .year {
			font-size: 0.875rem;
			color: #AAA;
		}

		/*Album view*/
		.albumView .details {
			display: flex;
			flex-flow: row nowrap;
			justify-content: flex-start;
		}

		.albumView .trackList {
			flex-grow: 1;
			max-width: calc(100% - 40px);
			cursor: default;
			margin-left: 20px;
		}

		.albumView .discNumber {
			font-weight: 600;
			margin-bottom: 5px;
		}

		.albumView li:not(:first-child) .discNumber {
			margin-top: 20px;
		}

		.albumView .discContent {
			margin-left: 20px;
		}

		.albumView li.song {
			padding-top: 8px;
			padding-bottom: 6px;
			border-bottom: 1px solid #DDD;
			list-style-type: unset;
			list-style-position: outside;
		}

		.albumView .trackArtist {
			color: #AAA;
		}

		.albumView li:first-child {
			padding-top: 0;
		}

		.albumView li:last-child {
			border-bottom: 0;
		}

		.albumView img {
			flex-shrink: 0;
			width: 100%;
			height: 100%;
			max-width: 15vw;
			max-height: 15vw;
			margin-bottom: 30px;
			border-radius: 5px;
		}
	</style>

</browser>
