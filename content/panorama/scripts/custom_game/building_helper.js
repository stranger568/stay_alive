'use strict';
 

const GSS = 7; //greed square size x*x
const BS = 3; //size of building
const MIN_DXY = (GSS - BS) / 2
const MAX_DXY = MIN_DXY + BS - 1;
const GCS = 64; //greed cell size
const StateCell =
{ 
	OUTZONE: [0, 0, 0, 40], //за зоной
	INZONEALLOW: [255, 255, 255, 100], //разрешено
	INZONEDENIED: [255, 0, 0, 100], //запрещено
	BUILDINGALLOW: [0, 255, 0, 100], //разрешено под зданием
	BUILDINGDENIED: [255, 255, 0, 100], //запрещено под зданием
	BUILDINGOUTZONE: [255, 0, 0, 100], //внезоны под зданием
}
const StateBuilding =
{
	ALLOW: [0, 255, 0, 75],
	DENIED: [255, 0, 0, 75]
}

const STATES =
{
	DISABLED: 'disabled',
	ACTIVE: 'active'
}

var boundTable = {}; //build bounds table
var placeBoundTable = {}; //placed buildings bounds table
var isAllowBuild = false; //safe check_build state
var state = 'disabled';
var size = 0;
var pressedShift = false;
var particle;
var buildingBase = [];

const Vec3 = (Vec4) => [Vec4[0], Vec4[1], Vec4[2]]
const VecAlpha = (Vec4) => [Vec4[3], 0, 0]
const SnapToGrid = (coord) => GCS * (0.5 + Math.floor(coord / GCS))

const StartBuildingHelper = (params) =>
{
  if (params.state != "disable")   { initStartBuildingHelper(params);}
  else	{ EndBuildingHelper();};
  if (state == STATES.ACTIVE) { activeStartBuildingHelper();};
}

const initStartBuildingHelper = (params) =>
{
  UpdateNetTable();
  var entIndex = params["entIndex"];
  var MaxScale = params["MaxScale"];
  var player = Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() );
  state = params["state"];
  pressedShift = GameUI.IsShiftDown();

  if (particle !== undefined)
  {
	Particles.DestroyParticleEffect(particle, true);
	for (var i = 0; i < buildingBase.length; i++)
	{
	  Particles.DestroyParticleEffect(buildingBase[i][0], true);
	}
	buildingBase = [];
  }

  $("#BuildingHelperBase").hittest = true;

  particle = Particles.CreateParticle("particles/buildinghelper/ghost_model.vpcf", ParticleAttachment_t.PATTACH_ABSORIGIN, player);
  Particles.SetParticleControlEnt(particle, 1, entIndex, ParticleAttachment_t.PATTACH_ABSORIGIN_FOLLOW, "follow_origin", Entities.GetAbsOrigin(entIndex), true);
  Particles.SetParticleControl(particle, 4, [ MaxScale, 0, 0 ]);


  for (var i = 0; i < GSS; i++)
  {
	for (var j = 0; j < GSS; j++)
	{
	  buildingBase.push([Particles.CreateParticle("particles/buildinghelper/square_sprite3.vpcf", ParticleAttachment_t.PATTACH_CUSTOMORIGIN, player), i, j]);
	  Particles.SetParticleControl(buildingBase[buildingBase.length - 1][0], 1, [GCS / 2, 0, 0]);
	}
  }
}

const activeStartBuildingHelper = () =>
{
  $.Schedule(1/60 , activeStartBuildingHelper);
  var mPos = GameUI.GetCursorPosition();
  var GamePos = Game.ScreenXYToWorld(mPos[0], mPos[1]);
  var GamePos2 = GamePos;
  GamePos[0] = SnapToGrid(GamePos[0]);
  GamePos[1] = SnapToGrid(GamePos[1]);


  // fix for borderless windowed players
  if (GamePos[0] > 10000000) { GamePos = [0, 0, 0]; }
  isAllowBuild = true;
  var left = GamePos[0] - (GSS / 2 - 0.5) * GCS;
  var top = GamePos[1] - (GSS / 2 - 0.5) * GCS;
  //клеточки
  for (var i = 0; i < buildingBase.length; i++)
  {
	var XX = left + buildingBase[i][1] * GCS;
	var YY = top + buildingBase[i][2] * GCS;
	var check_cell = IsBuildCell(XX, YY);

	if ((buildingBase[i][1] >= MIN_DXY) &&
		(buildingBase[i][1] <= MAX_DXY) &&
		(buildingBase[i][2] >= MIN_DXY) &&
		(buildingBase[i][2] <= MAX_DXY))
	{
	  isAllowBuild &= (check_cell == StateCell.INZONEALLOW);
	  switch (check_cell)
	  {
		case StateCell.INZONEALLOW:
			check_cell = StateCell.BUILDINGALLOW;
			break;
		case StateCell.INZONEDENIED:
			check_cell = StateCell.BUILDINGDENIED;
			break;
		case StateCell.OUTZONE:
			check_cell = StateCell.BUILDINGOUTZONE;
			break;
	  }
	}
	  Particles.SetParticleControl(buildingBase[i][0], 0, [XX, YY, GamePos[2] + 1]);
	  Particles.SetParticleControl(buildingBase[i][0], 2, Vec3(check_cell));
	  Particles.SetParticleControl(buildingBase[i][0], 3, VecAlpha(check_cell));
	  Particles.SetParticleControl(buildingBase[i][0], 4, GamePos2);
  }
  //здание
  Particles.SetParticleControl(particle, 0, [GamePos[0], GamePos[1], GamePos[2] + 1]);
  Particles.SetParticleControl(particle, 2, Vec3(isAllowBuild ? StateBuilding.ALLOW : StateBuilding.DENIED));
  Particles.SetParticleControl(particle, 3, VecAlpha(isAllowBuild ? StateBuilding.ALLOW : StateBuilding.DENIED));

  if (!GameUI.IsShiftDown() && pressedShift) { EndBuildingHelper(); }
}



const EndBuildingHelper = () =>
{
  $("#BuildingHelperBase").hittest = false;
  if (particle !== undefined)
  {
	Particles.DestroyParticleEffect(particle, true);
	for (let i = 0; i < buildingBase.length; i++)
	{
	  Particles.DestroyParticleEffect(buildingBase[i][0], true);
	}
	buildingBase = [];
  }
  state = STATES.DISABLED;
}


//right click
const SendBuildCommand = (params) =>
{
  if (isAllowBuild)
  {
	var mPos = GameUI.GetCursorPosition();
	var GamePos = Game.ScreenXYToWorld(mPos[0], mPos[1]);
	GamePos[0] = SnapToGrid(GamePos[0]);
	GamePos[1] = SnapToGrid(GamePos[1]);
	pressedShift = GameUI.IsShiftDown();
	GameEvents.SendCustomGameEventToServer("building_helper_build_command", { "X": GamePos[0], "Y": GamePos[1], "Z": GamePos[2], "Shift": pressedShift });
	if (!pressedShift) // Remove the green square unless the player is holding shift
	{
	  EndBuildingHelper("ok");
	}
  }
  else
  {
	SendCancelCommand("denied");
  }
}

//left click
const SendCancelCommand = (cmd) =>
{
  EndBuildingHelper();
  GameEvents.SendCustomGameEventToServer("building_helper_cancel_command", {"cmd" : cmd});
}




const UpdateNetTable = () =>
{
	boundTable = CustomNetTables.GetTableValue("stay_alive_buildingzone", "stay_alive_buildingzone");
	placeBoundTable = CustomNetTables.GetTableValue("stay_alive_buildingzone", "stay_alive_buildingzone_buildings");
}


//if cell is lock to building return false
const IsBuildCell = (XX, YY) =>
{
	var ret = StateCell.OUTZONE;
	for (let k in boundTable)
	{
	  if ((XX < boundTable[k].Xmax) &&
		  (XX > boundTable[k].Xmin) &&
		  (YY < boundTable[k].Ymax) &&
		  (YY > boundTable[k].Ymin))
	  {
		ret = StateCell.INZONEALLOW;
		break;
	  }
	}
	if (ret == StateCell.INZONEALLOW)
	{
		for (let i in placeBoundTable)
		{
			if ((XX < placeBoundTable[i].Xmax) &&
				(XX > placeBoundTable[i].Xmin) &&
				(YY < placeBoundTable[i].Ymax) &&
				(YY > placeBoundTable[i].Ymin))
			{
			  ret = StateCell.INZONEDENIED;
			  break;
			}
		}
	}
	return ret;
}

CustomNetTables.SubscribeNetTableListener("stay_alive_buildingzone", UpdateNetTable);
GameEvents.Subscribe("building_helper_enable", StartBuildingHelper);