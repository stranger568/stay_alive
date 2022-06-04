var _ = GameUI.CustomUIConfig()._;

function UpdatePanelBuild() {
	var wp = $.GetContextPanel().WorldPanel;
	var offScreen = $.GetContextPanel().OffScreen;
	if (!offScreen && wp) {
		var ent = wp.entity;
		if (ent) {
			if (!Entities.IsAlive(ent)) {
				$.GetContextPanel().style.opacity = "0";
				return;
			}
			if (wp.data.id_owner || wp.data.id_owner == 0)
			{
				$("#AvatarOwner").steamid = Game.GetPlayerInfo( wp.data.id_owner ).player_steamid
				$("#AvatarOwner").style.opacity = "1";
			} else {
				$("#AvatarOwner").style.opacity = "0";
			}
			$("#AvatarOwner").SetPanelEvent('onmouseover', function() {});
			$("#AvatarOwner").SetPanelEvent('onactivate', function() {});
			var hp = Entities.GetHealth(ent);
      		var hpMax = Entities.GetMaxHealth(ent);
      		var hpPer = (hp * 100 / hpMax).toFixed(0);
      		$("#HealthPanelBackgroundGreen").style.width = hpPer + "%;";
		}
	}
	$.Schedule(1 / 144, UpdatePanelBuild);
}

(function() {
	UpdatePanelBuild();
})();
