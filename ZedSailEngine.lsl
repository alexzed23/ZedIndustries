vector COLOR_GREEN = <0.0, 1.0, 0.0>;
float  OPAQUE      = 1.0;

integer objListener = 0;
integer objChannel  = PUBLIC_CHANNEL;
float   objTimerEvent = 0.5;
integer objNumPrims = 0;

float   vehicleEnergy = 100;
integer vehicleEngine = 0;

integer boomAngle  = 0;

float   hullAngle = 0.0;
vector  hullRot   = ZERO_VECTOR;
float   hullSpeed = 0.0;

integer sailUp = FALSE;

vector  vehicleReferenceFrame = ZERO_VECTOR;

objectShowInfo()
{
    string text = "";
    text += "Boom angle: " + boomAngle + "\n";
    text += "Hull angle: " + (string)hullAngle + "\n";
    text += "Hull speed: " + (string)hullSpeed + "\n";
    llSetText(text, COLOR_GREEN, OPAQUE );
}
objectHideInfo()
{
    string text = "";
    llSetText(text, COLOR_GREEN, OPAQUE );
}

vehicleSettings()
{
    llSitTarget(<-2.0, 0.3, 0.85>,llEuler2Rot(<0.0,0.0,-90.0*DEG_TO_RAD>));

    llSetVehicleType         (VEHICLE_TYPE_BOAT);
    llSetVehicleRotationParam(VEHICLE_REFERENCE_FRAME,ZERO_ROTATION);
    llSetVehicleFlags        (VEHICLE_FLAG_NO_DEFLECTION_UP|VEHICLE_FLAG_HOVER_GLOBAL_HEIGHT|VEHICLE_FLAG_LIMIT_MOTOR_UP );

    llSetVehicleVectorParam  (VEHICLE_LINEAR_FRICTION_TIMESCALE,<50.0,2.0,0.5>);;
    llSetVehicleVectorParam  (VEHICLE_LINEAR_MOTOR_DIRECTION,ZERO_VECTOR);
    llSetVehicleFloatParam   (VEHICLE_LINEAR_MOTOR_TIMESCALE,10.0);
    llSetVehicleFloatParam   (VEHICLE_LINEAR_MOTOR_DECAY_TIMESCALE,60);
    llSetVehicleFloatParam   (VEHICLE_LINEAR_DEFLECTION_EFFICIENCY,0.85);
    llSetVehicleFloatParam   (VEHICLE_LINEAR_DEFLECTION_TIMESCALE,1.0);

    llSetVehicleVectorParam  (VEHICLE_ANGULAR_FRICTION_TIMESCALE,<5,0.1,0.1>);
    llSetVehicleVectorParam  (VEHICLE_ANGULAR_MOTOR_DIRECTION,ZERO_VECTOR);
    llSetVehicleFloatParam   (VEHICLE_ANGULAR_MOTOR_TIMESCALE,0.1);
    llSetVehicleFloatParam   (VEHICLE_ANGULAR_MOTOR_DECAY_TIMESCALE,100);
    llSetVehicleFloatParam   (VEHICLE_ANGULAR_DEFLECTION_EFFICIENCY,1.0);
    llSetVehicleFloatParam   (VEHICLE_ANGULAR_DEFLECTION_TIMESCALE,1.0);

    llSetVehicleFloatParam   (VEHICLE_VERTICAL_ATTRACTION_TIMESCALE,3.0);
    llSetVehicleFloatParam   (VEHICLE_VERTICAL_ATTRACTION_EFFICIENCY,0.8);

    llSetVehicleFloatParam   (VEHICLE_BANKING_EFFICIENCY,0.0);
    llSetVehicleFloatParam   (VEHICLE_BANKING_MIX,1.0);
    llSetVehicleFloatParam   (VEHICLE_BANKING_TIMESCALE,1.2);

    llSetVehicleFloatParam   (VEHICLE_HOVER_HEIGHT,llWater(ZERO_VECTOR));
    llSetVehicleFloatParam   (VEHICLE_HOVER_EFFICIENCY,2.0);
    llSetVehicleFloatParam   (VEHICLE_HOVER_TIMESCALE,1.0);
    llSetVehicleFloatParam   (VEHICLE_BUOYANCY,1.0);

}

vehicleParseMessage(key id, string message)
{
    if (message == "com_raise")
    {
        sailUp = TRUE;
        llSetStatus(STATUS_PHYSICS, TRUE);
        llMessageLinked(LINK_ALL_CHILDREN, 0, "com_raise", NULL_KEY);

    } else if (message == "com_lower") {

            sailUp = FALSE;
        llSetStatus(STATUS_PHYSICS, FALSE);
        llMessageLinked(LINK_ALL_CHILDREN, 0, "com_lower", NULL_KEY);
    }
}

vehicleTimer()
{
}
vehicleAvatarOn()
{
}
vehicleAvatarOff()
{
}

default
{
    state_entry()
    {
        objNumPrims = llGetNumberOfPrims();
        objListener = llListen(objChannel, "",NULL_KEY,"");

        vehicleSettings();
        
        boomAngle  = 0;

        llSetTimerEvent(1.0);
        
        
    }
    listen(integer channel, string name, key id, string message)
    {
        vehicleParseMessage(id, message);
    }
    timer()
    {
        if (sailUp)
        {
            rotation  rot = llGetRot();
            vector    ERot = llRot2Euler(rot);
            float     angle = ERot.z + (DEG_TO_RAD*boomAngle);
            hullSpeed = llCos(angle)*5;
            llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION,<hullSpeed,0.0,0.0>);
            objectShowInfo();
        }
        else
        {
            llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION,<0.0,0.0,0.0>);
            objectHideInfo();
        }
    }
    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            if (llGetNumberOfPrims() > objNumPrims)
            {
                vehicleAvatarOn();
                llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS |
                    PERMISSION_TRACK_CAMERA |
                    PERMISSION_CONTROL_CAMERA |
                    PERMISSION_TRIGGER_ANIMATION
                        );
            }
            if (llGetNumberOfPrims() == objNumPrims)
            {
            }
        }
    }
    run_time_permissions(integer perm)
    {
        if(PERMISSION_TAKE_CONTROLS & perm)
        {
            llTakeControls(
                CONTROL_FWD |
                CONTROL_BACK |
                CONTROL_LEFT |
                CONTROL_RIGHT |
                CONTROL_ROT_LEFT |
                CONTROL_ROT_RIGHT |
                CONTROL_UP |
                CONTROL_DOWN |
                CONTROL_LBUTTON |
                CONTROL_ML_LBUTTON ,
                TRUE, FALSE);

        }
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            llStopAnimation("stand");
            llStartAnimation("sit");
        }
    }
    control(key id, integer level, integer edge)
    {
        integer start = level & edge;
        integer end = ~level & edge;
        integer held = level & ~edge;
        if (start & CONTROL_UP)
        {
            llMessageLinked(LINK_ALL_CHILDREN, 0, "CONTROL_UP", NULL_KEY);
        }
        else if (start & CONTROL_DOWN)
        {
            llMessageLinked(LINK_ALL_CHILDREN, 0, "CONTROL_DOWN", NULL_KEY);
        }
        else if (start & CONTROL_FWD)
        {
            if (boomAngle > -45)
            {
                boomAngle-=15;
                llMessageLinked(LINK_ALL_CHILDREN, -15, "CONTROL_FWD", NULL_KEY);
            }
        }
        else if (start & CONTROL_BACK)
        {
            if (boomAngle < 45)
            {
                boomAngle+=15;
                llMessageLinked(LINK_ALL_CHILDREN, 15, "CONTROL_BACK", NULL_KEY);
            }
        }
        else if (start & CONTROL_ROT_LEFT)
        {
            llSetVehicleVectorParam(VEHICLE_ANGULAR_MOTOR_DIRECTION,<0.0,0.0,1.0>);
            llMessageLinked(LINK_ALL_CHILDREN, 0, "CONTROL_ROT_LEFT", NULL_KEY);
        }
        else if (end & CONTROL_ROT_LEFT)
        {
            hullRot   = llRot2Euler(llGetRot());
            hullAngle = RAD_TO_DEG*hullRot.z;
            llMessageLinked(LINK_ALL_CHILDREN, 0, "CONTROL_ROT_LEFT", NULL_KEY);
            llSetVehicleVectorParam(VEHICLE_ANGULAR_MOTOR_DIRECTION,ZERO_VECTOR);
        }
        else if (start & CONTROL_ROT_RIGHT)
        {
            llSetVehicleVectorParam(VEHICLE_ANGULAR_MOTOR_DIRECTION,<0.0,0.0,-1.0>);
            llMessageLinked(LINK_ALL_CHILDREN, 0, "CONTROL_ROT_RIGHT", NULL_KEY);
        }
        else if (end & CONTROL_ROT_RIGHT)
        {
            hullRot   = llRot2Euler(llGetRot());
            hullAngle = RAD_TO_DEG*hullRot.z;
            llMessageLinked(LINK_ALL_CHILDREN, 0, "CONTROL_ROT_RIGHT", NULL_KEY);
            llSetVehicleVectorParam(VEHICLE_ANGULAR_MOTOR_DIRECTION,ZERO_VECTOR);
        }
    }
}
