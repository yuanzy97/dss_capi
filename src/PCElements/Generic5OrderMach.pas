﻿unit Generic5OrderMach;

{   Change Log

   November 3, 2017

   Created by
     Darhey  Xu

}

interface

uses
    DSSClass,   // Base class for most DSS objects
    PCClass,    // Base class for collection manager for PC elements
    PCElement,  // Base class for PC  Elements
    ucmatrix,     // Unit for managing complex matrice (for Yprim, etc)
    ucomplex,     // Complex math functions, type definitions
    ArrayDef,     // definitions of basic DSS arrays

    // common modules used in PC elements
    LoadShape,    // class for supporting/representing loadshapes
    GrowthShape,  // Class for holding growth shapes
    Spectrum,     // Definitions for harmonic spectra
    Dynamics,
    GeneratorVars;     // for elements that interact with dynamics variables

type

// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

{ Collection manager for this class of element }
    TGeneric5 = class(TPCClass)   { Notes Andres: -- definition of the class -- }
    PRIVATE

      {These private functions are generally helper functions for Edit procedure}

      { A typical function }
        procedure SetNcondsForConnection;

    PROTECTED
        procedure DefineProperties;    // Define the property names and help strings
        function MakeLike(const OtherIndMach012Name: String): Integer; OVERRIDE;  // copy properties of another similar object

    PUBLIC

        constructor Create;
        destructor Destroy; OVERRIDE;

        function Edit: Integer; OVERRIDE;      // Definition of the main property editing function
        function Init(Handle: Integer): Integer; OVERRIDE;  // Initialize by handle (index), if necessary

        function NewObject(const ObjName: String): Integer; OVERRIDE; // This function is called by the DSS New command

     {any public functions that might be called from other elements}

    end;

{ Class definition for this class of element}
    TSymCompArray5 = array[0..2] of Complex;
    //pTDynamicsRec =  ^TDynamicsRec;
    //pTGeneratorVars = ^TGeneratorVars;

    TGeneric5Obj = class(TPCElement)
    PRIVATE

      {Private variables of this class}
        Connection: Integer;  {0 = line-neutral; 1=Delta}
        Yeq: Complex;   // Y at nominal voltage

        puRs, puXs, puRr, puXr, puXm,
        //S1,        // Pos seq slip
        //S2,
        MaxSlip,  // limit for slip to prevent solution blowing up
        //dSdP,  // for power flow

        {Dynamics variables}
        Xopen,
        Xp,
        T0p // Rotor time constant
        : Double;
        //NOrder, //NOrder = 5 is defined as constant
        NumOrderX, //  system order
        NumOrderY: Integer; //  system output Y order
        {X,V}
        {  X_var:pComplexArray;
          Y_out_var :pComplexArray;
          V_in_var :pComplexArray;
        {A, B Matrix }
        {  Amm:pComplexArray;
          Bmn:pComplexArray;
          Cnm:pComplexArray;
          Dnn:pComplexArray;
        {}
        X_var: pdoubleArray;
        dX_vardt: pdoubleArray;
        X_varn: pdoubleArray;//for tropdize integrate
        dX_vardtn: pdoubleArray;
        Y_out_var: pdoubleArray;
        V_in_var: pdoubleArray;
        pV_f_CC: pdoublearray;
        CC_Switch: Boolean;
          //Cluster_num : integer;
        {A, B Matrix }
        Amm: pdoubleArray;
        Bmn: pdoubleArray;
        Cnm: pdoubleArray;
        Dnn: pdoubleArray;
        {}

        InDynamics: Boolean;
        Zs, Zm, Zr: Complex;
        Is1, Ir1, V1,    // Keep the last computed voltages and currents
        Is2, Ir2, V2: Complex;

        {Complex variables for dynamics}
        //E1, E1n, dE1dt, dE1dtn,
        //E2, E2n, dE2dt, dE2dtn,
        Zsp: Complex;

        {}
        Id, Iq: Double; //Id related to P ; Iq related to Q
        flag_dyna_Id_chg: Boolean;

        dIddt, dIqdt: Double;
        Idn, Iqn, dIddtn, dIqdtn: Double; //save last time step for integration.
        {the input for control purpose}
        kcd, kcq, kcq_drp2: Double; //the control gain in vi1, vi2
        Volt_Trhd: Double;
        droop: Integer;//droop type: 2, Q = kcq_drp2 * (1-v_dg). others: integral droop with kcq
        //flag_drp2 : integer; //if it is 1, drp2
        kqi: Double; //control gain for Q_ref
        vi1, vi2: Double; //the input of the control
        vi1n, vi2n: Double; //the input of the control
        dvi1dt, dvi2dt, dvi1dtn, dvi2dtn: Double;
        Id_ref, Iq_ref: Double; // The pursued value of Id related to P ; Iq related to Q
        {}
        P_ref, Q_ref, V_ref: Double;//Power and voltage goal of the machine
        DPX: Double;
        ctrl_mode: Integer; //ctrl_mode 0-local droop  V_ref = V_DG_0, P_ref = P_DG_0
        {}
        P_DG, Q_DG: Double; //power of all phases totally in one
        V_DG: Double;// the voltage magetitude of current bus
        Theta_DG: Double; //the voltage angel of DG bus to slack
        //Cluster_Num : integer; //the cluster define         --move to PCElement
        //Num_in_Cluster : integer; // node num in cluster;   --move to PCElement
        QV_flag: Integer; // 0 Q_ref; 1 V_ref
        //QV_flag_0 : integer;
        //QV_switch: integer; //if Q hits limits, PV to PQ, the QV_switch:= 1; each time Edit function runs, check this and set QV_flag back to user set.
        {--for 3 phases--}
        //power, voltage, angle,
        P_DG1, P_DG2, P_dg3,
        Q_DG1, Q_dg2, Q_dg3,
        V_DG1, V_DG2, V_DG3,
        V_theta1, V_theta2, V_theta3: Double;//operation values
        Id1, Iq1, Id2, Iq2, Id3, Iq3: Double; //currents
        //set values
        P_ref1, P_ref2, P_ref3,
        Q_ref1, Q_ref2, Q_ref3,
        V_ref1, V_ref2, V_ref3: Double;// set values from outside
        {------Max Check-------}
          //SMax; //  MachineData.kVArating; // 'g1.kva=100'
        PMax, // Activity power output limit
        PMax_phase, //limit per phase
        PMin,  //(0, default)   // 'g1.pmax=100'
        Pmin_phase, //
        Qmax, //Reactive power output limit
        Qmax_phase,
        Qmin, //(-Qmax, default)
        Qmin_phase: Double; //
        IdMax_phase,
        IqMax_phase: Double;//phase current limit
        PQpriority: Integer; //Active and reactive power control mode, control s
                            //'g1.pqvflag=0 Q, 1 P;
          ///////////////////
          //Gradient ; move to public
          //Alpha, // Alpha := Q_DG/Qmax;
          //dAlpha,
          //Gradient: double;
          {----------------------}
            //equivalent frequency
        freq: Double;
        z_dfs_plot: Double;
          {----------------------}
        FirstIteration, FixedSlip: Boolean;

        //var_Remembered  :Double; //Q remembered of last calc
        DQDV: Double;  //for P_ref V_ref model

        RandomMult: Double;
        //Generic5SolutionCount : Integer;
        Generic5SwitchOpen: Boolean;

        // Debugging
        TraceFile: TextFile;
        DebugTrace: Boolean;

        MachineData: TGeneratorVars;    // Use generator variable structure

        // Andres: NEW variables from generator
        MachineON: Boolean;
        ShapeFactor: Complex;

        ShapeIsActual: Boolean;
        // Andres: end NEW variables from generator

        VBase: Double;
        kWBase: Double;
         {---deal with -Update_Pmax_by_Ftrs-}
        Pmpp,//Pmpp, default value is 1.0;
        Pbias, //Pbias, default value is 0.0;
        Pfctr1,//factors, default value all are 1.0;
        Pfctr2,
        Pfctr3,
        Pfctr4,
        Pfctr5,
        Pfctr6: Double;

         {----------------}
                 //Gradient ; public
        Alpha, // Alpha := Q_DG/Qmax;  //pos ctrl
        dAlpha,
        Gradient: Double;
        Alpha1, Alpha2, Alpha3, // Alpha := Q_DG/Qmax;  //pos ctrl
        dAlpha1, dAlpha2, dAlpha3,
        Gradient1, Gradient2, Gradient3: Double;
        AlphaP, AlphaP1, AlphaP2, AlphaP3: Double;// for active P control
        GradientP, GradientP1, GradientP2, GradientP3: Double;
//        Procedure InterpretOption(s:String);

        //procedure set_Localslip(const Value: Double);

        //Procedure Get_PFlowModelCurrent(Const V:Complex; Const S:Double; var Istator, Irotor:Complex);
        procedure Get_DynamicModelCurrent;
        //procedure Set_Slip(const Value: Double);

        function GetRotorLosses: Double;
        function GetStatorLosses: Double;
        //Function  Compute_dSdP:Double;
        procedure Randomize(Opt: Integer);
        procedure InitModel(V012, I012: TSymCompArray5);
        procedure InitModelVIabc;

        procedure CalcYPrimMatrix(Ymatrix: TcMatrix);
        procedure CalcGeneric5ModelContribution;
        procedure CalcInjCurrentArray;

        procedure DoGeneric5Model;
        procedure CalcModel(V, I: pComplexArray);


        // Andres: NEW procedures from generator
        procedure CalcDailyMult(Hr: Double);
        procedure CalcYearlyMult(Hr: Double);
        procedure CalcDutyMult(Hr: Double);
        // Andres: NEW procedures from generator

        procedure InitTraceFile;
        procedure WriteTraceRecord;
        function Get_PresentkV: Double;
        procedure Set_PresentkV(const Value: Double);

        procedure SetPowerkW(const PkW: Double);
        {}
        procedure update_controlinput;
        procedure update_pV_f_CC;//  update cooperate control part, pV_f_CC
        procedure update_pV_f_CC_M2;//  update cooperate control part, pV_f_CC
        procedure update_system_abcd;
        procedure Set_P_Ref(PrefkW: Double);
        procedure Set_Q_Ref(QrefkVAr: Double);
        procedure Set_V_Ref(VrefkV: Double);
        procedure Update_kWbase_by_Fctrs;
        procedure Update_PQlimits; //real time limits check
                                    // can also be used in power flow and simulation
        procedure InfoPublish;
        //Procedure Get_Bii;
        procedure CalGradient;
//        Procedure CalcDQDV;
    PROTECTED

        {A couple of virtual procedures you can override}
        procedure Set_ConductorClosed(Index: Integer; Value: Boolean); OVERRIDE;
        procedure GetTerminalCurrents(Curr: pComplexArray); OVERRIDE;

        procedure DoDynamicMode;
        procedure DoHarmonicMode;

    PUBLIC

        {Variables and functions accessed by DSS and other objects}

        // Andres: new variables from generator
        DailyDispShape: String;  // Daily (24 HR) Generator shape
        DailyDispShapeObj: TLoadShapeObj;  // Daily Generator Shape for this load
        DutyShapeObj: TLoadShapeObj;  // Shape for this generator
        DutyShape: String;  //
        YearlyShape: String;  // ='fixed' means no variation  on all the time
        YearlyShapeObj: TLoadShapeObj;  // Shape for this Generator
        // Andres: New variables from generator

        constructor Create(ParClass: TDSSClass; const Generic5ObjName: String);
        destructor Destroy; OVERRIDE;

        procedure RecalcElementData; OVERRIDE;   // Generally called after Edit is complete to recompute variables
        procedure CalcYPrim; OVERRIDE;   // Calculate Primitive Y matrix
        {-----------}
//        Procedure CalcABMatrix;
        {-----------}
        procedure Integrate;
        procedure IntegrateABCD;
        procedure CalcDynamic(var V012, I012: TSymCompArray5);
        procedure CalcPFlow(var V012, I012: TSymCompArray5);
        // for abc phases: the below 2
        procedure CalcDynamicVIabc(var Vabc, Iabc: pComplexArray);
        procedure CalcPFlowVIabc(var Vabc, Iabc: pComplexArray);

        procedure SetNominalPower;
        procedure UpdateAlpha_qi; // \alpha_qi := Q_DG/Qmax;

        function InjCurrents: Integer; OVERRIDE;
        procedure GetInjCurrents(Curr: pComplexArray); OVERRIDE;

          // State variable management functions, if any
        // You can omit these if your PC element model is not using these
        // Default behavior is to basically do nothing
        function NumVariables: Integer; OVERRIDE;
        procedure GetAllVariables(States: pDoubleArray); OVERRIDE;
        function Get_Variable(i: Integer): Double; OVERRIDE;
        procedure Set_Variable(i: Integer; Value: Double); OVERRIDE;
        function VariableName(i: Integer): String; OVERRIDE;

        // Support for Dynamics Mode
        procedure InitStateVars; OVERRIDE;
        procedure IntegrateStates; OVERRIDE;

        // Support for Harmonics Mode
        procedure InitHarmonics; OVERRIDE;

        procedure MakePosSequence; OVERRIDE;  // Make a positive Sequence Model, if possible

       // Functions required for managing values of properties
        procedure InitPropertyValues(ArrayOffset: Integer); OVERRIDE;
        procedure DumpProperties(var F: TextFile; Complete: Boolean); OVERRIDE;
        function GetPropertyValue(Index: Integer): String; OVERRIDE;

       // Property LocalSlip:Double read S1 write set_Localslip;
        //Property Slip:Double              Write Set_Slip;
        property PresentkV: Double READ Get_PresentkV WRITE Set_PresentkV;

    end;


var
    Generic5Class: TGeneric5;
    ActiveGeneric5Obj: TGeneric5Obj;


implementation

{Typical Uses Clause -- not all may not be needed}
uses
    ParserDel,     // DSS parser
    DSSClassDefs,  // Where class is instantiated
    DSSGlobals,    // Global DSS variables
    Circuit,       // If access to circuit variables is needed
    Command,       // DSS command and property support module
    Sysutils,      // Delphi misc utility functions
    Math,          // Delphi Math functions
    MathUtil,      // DSS Math utilities
    Utilities;     // DSS misc utility functions

const
    NumPropsThisClass = 48;//44;//24;//23; // Set this constant to the actual number of properties you define   add grpnum
    NumGeneric5Variables = 36;//33;//25;//24;
    nOrder = 6;

var  // Define any useful module vars here, for example:
    cBuffer: array[1..24] of Complex;  // Temp buffer for complex math calcs; allows up to 24-phase models.
    CDOUBLEONE: Complex;   // 1 + j1  (see Initialization section below)

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
constructor TGeneric5.Create;  // Creates main collection handler for all IndMach012 objects
begin
    inherited Create;  // make the base class  and init DSSClassType

     // Specify class name and bit mask ID for this class type
     // IndMach012_ELEMENT must be defined in DSSClassDefs as nn*8
     // First 3 bits are used for base class type (DSSClassType)
    Class_Name := 'Generic5';
    DSSClassType := DSSClassType + Generic5OrderMach_ELEMENT;

    ActiveElement := 0;   // no active elements yet; init to 0

     {Initialize any other special variables here}

    DefineProperties;   // This is where the properties for this class are defined

     // Use the Command processor to manage property names
     // PropertyName is an array of String defined in DefineProperties
    CommandList := TCommandList.Create(Slice(PropertyName^, NumProperties));
    CommandList.Abbrev := TRUE;

    Generic5Class := Self;
end;

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
destructor TGeneric5.Destroy;

begin

    // ElementList and  CommandList freed in inherited destroy
    inherited Destroy;

end;

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
procedure TGeneric5.DefineProperties;

// This is where the properties are defined, assigned names, indexes, and help strings
// The Help strings will automatically show up when the Help is invoked

begin

    Numproperties := NumPropsThisClass;
    CountProperties;   // Get inherited property count
    AllocatePropertyArrays;   {see DSSClass}

     // Refer to other classes for alternative methods of assigning properties
     // This example uses the AddProperty function to assign Name, Index, and Help string
     // in one statement.

     // First argument is string name of the property
     // Second argument is the index for the CASE statement
     // Third argument is help string

     // DSS properties are accessed in sequence if the property name is not explicitly specified.
     // The advantage of using the AddProperty function is that you may change the sequence simply
     // by shuffling the order of the definitions and you do not have to change the index in the CASE
     // statement in the EDIT function


    PropertyName[1] := 'phases';
    PropertyName[2] := 'bus1';
    PropertyName[3] := 'kv';
    PropertyName[4] := 'kW';
    PropertyName[5] := 'pf';
    PropertyName[6] := 'conn';
    PropertyName[7] := 'kVA';
    PropertyName[8] := 'H';
    PropertyName[9] := 'D';
    PropertyName[10] := 'P_ref1kW';
    PropertyName[11] := 'P_ref2kW';
    PropertyName[12] := 'P_ref3kW';
    PropertyName[13] := 'V_ref1kVLN';
    PropertyName[14] := 'V_ref2kVLN';
    PropertyName[15] := 'V_ref3kVLN';
    PropertyName[16] := 'MaxSlip';
    PropertyName[17] := 'SlipOption';
    PropertyName[18] := 'Yearly';
    PropertyName[19] := 'Daily';
    PropertyName[20] := 'Duty';
    PropertyName[21] := 'Debugtrace';
    PropertyName[22] := 'P_refkW';
    PropertyName[25] := 'V_refkVLN';
    PropertyName[23] := 'Q_refkVAr';
    PropertyName[24] := 'Cluster_num';
    PropertyName[26] := 'ctrl_mode';
     ///////////////////////////////////////////
     /// contrl mode
     ///    ctrl_mode =0; phases = 3;  // pos avg control---p_ref, V_ref, Q_ref
     ///    ctrl_mode =1; phases = 1; bus1 = 452.1;      ---p_ref1, V_ref1, Q_ref1
     ///    ctrl_mode =2; phases = 1; bus1 = 452.2;      ---p_ref2, V_ref2, Q_ref2
     ///    ctrl_mode =3; phases = 1; bus1 = 452.3;      ---p_ref3, V_ref3, Q_ref3
     ///    ctrl_mode =4; phases = 3; bus1 = 452.2;      ---p_ref1,2,3, V_ref1,2,3, Q_ref1,2,3
    PropertyName[27] := 'QV_flag';
    PropertyName[28] := 'kcd';//Idi control gain
    PropertyName[29] := 'kcq';//Iqi control gain to delta V
    PropertyName[30] := 'kqi';//Iqi control gain to delta Q
    PropertyName[31] := 'Q_ref1kVAr';
    PropertyName[32] := 'Q_ref2kVAr';
    PropertyName[33] := 'Q_ref3kVAr';
    PropertyName[34] := 'PmaxkW'; //
    PropertyName[35] := 'PminkW';
    PropertyName[36] := 'PQpriority';
    PropertyName[37] := 'PmppkW';
    PropertyName[38] := 'Pfctr1';
    PropertyName[39] := 'Pfctr2';
    PropertyName[40] := 'Pfctr3';
    PropertyName[41] := 'Pfctr4';
    PropertyName[42] := 'Pfctr5';
    PropertyName[43] := 'Pfctr6';
    PropertyName[44] := 'PbiaskW';
    PropertyName[45] := 'CC_Switch';
    PropertyName[46] := 'kcq_drp2';
    PropertyName[47] := 'Volt_Trhd';
    PropertyName[48] := 'droop';

     //PropertyName[46] := 'Num_in_Cluster. Num_in_Cluster = 1~33';

    PropertyHelp[1] := 'Number of Phases, this Induction Machine.  ';
    PropertyHelp[2] := 'Bus to which the Induction Machine is connected.  May include specific node specification.';
    PropertyHelp[3] := 'Nominal rated (1.0 per unit) voltage, kV. For 2- and 3-phase machines, specify phase-phase kV. ' +
        'Otherwise, specify actual kV across each branch of the machine. ' +
        'If wye (star), specify phase-neutral kV. ' +
        'If delta or phase-phase connected, specify phase-phase kV.';  // line-neutral voltage//  base voltage
    PropertyHelp[4] := 'Shaft Power, kW, for the Induction Machine. Output limit of a DG';//A positive value denotes power for a //load. ';//+CRLF+
                        //'Negative value denotes an induction generator. ';
    PropertyHelp[5] := '[Read Only] Present power factor for the machine. ';
    PropertyHelp[6] := 'Connection of stator: Delta or Wye. Default is Delta.';
    PropertyHelp[7] := 'Rated kVA for the machine.';
    PropertyHelp[8] := 'Per unit mass constant of the machine.  MW-sec/MVA.  Default is 1.0.';
    PropertyHelp[9] := 'Damping constant.  Usual range is 0 to 4. Default is 1.0.  Adjust to get damping in Dynamics mode,';
    PropertyHelp[10] := 'P_ref1kW = 10, goes to P_ref1, unit kW, 1st phase set power';
    PropertyHelp[11] := 'P_ref2kW = 10, goes to P_ref2, unit kW, 2nd phase set power';
    PropertyHelp[12] := 'P_ref3kW = 10, goes to P_ref3, unit kW, 3rd phase set power';
    PropertyHelp[13] := 'V_ref1kVLN = 2.16, 1st phase set V, (Unit kV, L-N value): V mode will work if QV_flag =1(by default) V_ref is set which is prior to Q_ref ';
    PropertyHelp[14] := 'V_ref2kVLN = 2.16, 2nd phase set V, (Unit kV, L-N value): V mode will work if QV_flag =1(by default) V_ref is set which is prior to Q_ref ';
    PropertyHelp[15] := 'V_ref3kVLN = 2.16, 3rd phase set V, (Unit kV, L-N value): V mode will work if QV_flag =1(by default) V_ref is set which is prior to Q_ref ';
    PropertyHelp[16] := 'Max slip value to allow. Default is 0.1. Set this before setting slip.';
    PropertyHelp[17] := 'Option for slip model. One of {fixedslip | variableslip*  }';
    PropertyHelp[18] := 'LOADSHAPE object to use for yearly simulations.  Must be previously defined ' +
        'as a Loadshape object. Is set to the Daily load shape ' +
        ' when Daily is defined.  The daily load shape is repeated in this case. ' +
        'Set Status=Fixed to ignore Loadshape designation. ' +
        'Set to NONE to reset to no loadahape. ' +
        'The default is no variation.';
    PropertyHelp[19] := 'LOADSHAPE object to use for daily simulations.  Must be previously defined ' +
        'as a Loadshape object of 24 hrs, typically. ' +
        'Set Status=Fixed to ignore Loadshape designation. ' +
        'Set to NONE to reset to no loadahape. ' +
        'Default is no variation (constant) if not defined. ' +
        'Side effect: Sets Yearly load shape if not already defined.';
    PropertyHelp[20] := 'LOADSHAPE object to use for duty cycle simulations.  Must be previously defined ' +
        'as a Loadshape object.  Typically would have time intervals less than 1 hr. ' +
        'Designate the number of points to solve using the Set Number=xxxx command. ' +
        'If there are fewer points in the actual shape, the shape is assumed to repeat.' +
        'Set to NONE to reset to no loadahape. ' +
        'Set Status=Fixed to ignore Loadshape designation. ' +
        ' Defaults to Daily curve If not specified.';
    PropertyHelp[21] := '[Yes | No*] Write DebugTrace file.';
    PropertyHelp[22] := 'P_refkW = 10, goes to P_ref. Ref P Value (kW). P_ref has prority to kW which is nomimal value. (Incide variable P_ref is W)';
    PropertyHelp[25] := 'V_refkVLN = 2.16, pos sequence set V. V_ref (Unit kV, L-N value): V mode will work if QV_flag =1(by default) V_ref is set which is prior to Q_ref';
    PropertyHelp[23] := 'Q_refkVAr=10. Unit Qvar. Ref Q kVAr Value: work only when V_ref is not set';
    PropertyHelp[24] := 'Cluster_num: has to be coincident with Fmonitor attached. Default value is 0';
     { add properties here }
    PropertyHelp[26] := 'ctrl mode:     /// contrl mode    ' +
        ' ///    ctrl_mode =0; phases = 3;  // pos avg control---p_ref, V_ref, Q_ref    \n ' + CRLF +
        ' ///    ctrl_mode =1; phases = 1; bus1 = 452.1;      ---p_ref1, V_ref1, Q_ref1 \n' + CRLF +
        '///    ctrl_mode =2; phases = 1; bus1 = 452.2;      ---p_ref2, V_ref2, Q_ref2 \n' + CRLF +
        '///    ctrl_mode =3; phases = 1; bus1 = 452.3;      ---p_ref3, V_ref3, Q_ref3 \n' + CRLF +
        '///    ctrl_mode =4; phases = 3; bus1 = 452.2;      ---p_ref1,2,3, V_ref1,2,3, Q_ref1,2,3';
    PropertyHelp[27] := 'QV_flag : 0-Q_ref mode; 1- V_ref mode';
    PropertyHelp[28] := 'kcd: Idi control gain';
    PropertyHelp[29] := 'kcq: Iqi control gain to delta V';
    PropertyHelp[30] := 'kqi: Iqi control gain to delta Q';
    PropertyHelp[31] := 'Q_ref1kVAr=10. Unit Qvar. Ref Q kVAr Value: work only when V_ref is not set';
    PropertyHelp[32] := 'Q_ref2kVAr=10. Unit Qvar. Ref Q kVAr Value: work only when V_ref is not set';
    PropertyHelp[33] := 'Q_ref3kVAr=10. Unit Qvar. Ref Q kVAr Value: work only when V_ref is not set';
    PropertyHelp[34] := 'PmaxkW = 100, goes to Pmax, unit kW, set max active power output; Operation limit of active power for DG' + CRLF + '  Pmax should be less than or equal to kW';
    PropertyHelp[35] := 'PminkW = 10, goes to Pmin, unit kW; Operation limit of active power for DG';
    PropertyHelp[36] := 'PQpriority, goes to PQpriority, define how to set Qmax. 0: Q,1: P ';
    PropertyHelp[37] := 'PmppkW = 100, goes to Pmpp, unit kW, input Pmpp to calculate kW;' + CRLF + '  kW := (Pmpp + Pbias)*Pfctr1*Pfctr2*Pfctr3*Pfctr4*Pfctr5*Pfctr6;' + CRLF + 'Pbias = 0 by default, Pfctr*=1 by default; These properties will overwrite kW.';
    PropertyHelp[38] := 'Pfctr1 = 0.16, see PmppkW';
    PropertyHelp[39] := 'Pfctr2 = 1, 1 by default, see PmppkW';
    PropertyHelp[40] := 'Pfctr3 = 1, 1 by default, see PmppkW';
    PropertyHelp[41] := 'Pfctr4= 1, 1 by default, see PmppkW';
    PropertyHelp[42] := 'Pfctr5 =1, 1 by default, see PmppkW';
    PropertyHelp[43] := 'Pfctr6 = 1, 1 by default, see PmppkW';
    PropertyHelp[44] := 'Pbias = -0.1, 0 by default, see PmppkW';
    PropertyHelp[45] := 'CC_Switch: default value is false.' + CRLF + 'CC_Switch = true --cooperate control on' + CRLF + 'CC_Switch = false -- cooperate control off';
    PropertyHelp[46] := 'kcq_drp2. the droop gain: 0.0~0.1';
    PropertyHelp[47] := 'Volt_Trhd. 0.~0.05. 0 means v has to follow v_ref';
    PropertyHelp[48] := 'droop type: integer: 2- Q = kcq_drp2 * (1-v_dg). others: integral droop with kcq.';
     // Finally, we have to pick up any properties that were inherited
    ActiveProperty := NumPropsThisClass;
    inherited DefineProperties;  // Add defs of inherited properties to bottom of list

     // You can optionally override default help string of an inherited property, for example
    PropertyHelp[NumPropsThisClass + 1] := 'Name of harmonic voltage or current spectrum for this IndMach012. ' +
        'Voltage behind Xd" for machine - default. Current injection for inverter. ' +
        'Default value is "default", which is defined when the DSS starts.';

end;

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function TGeneric5.NewObject(const ObjName: String): Integer;

// This function is called  by the DSS whenever a New IndMach012... command is encountered

begin
    // Make a new IndMach012 and add it to IndMach012 class list
    with ActiveCircuit do
    begin
        ActiveCktElement := TGeneric5Obj.Create(Self, ObjName);
        Result := AddObjectToList(ActiveDSSObject);
    end;

end;

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
procedure TGeneric5.SetNcondsForConnection;

// This is a typical helper function found in many DSS circuit element class
// for defining the number of conductors per terminal (Nconds) based on Y or delta connection

begin

    with ActiveGeneric5Obj do
    begin
        case Connection of
            0:
                NConds := Fnphases;  // Neutral is not connected for induction machine
            1:
                case Fnphases of        // Delta connection
                    1, 2:
                        NConds := Fnphases + 1; // L-L and Open-delta
                else
                    NConds := Fnphases;    // no neutral for this connection
                end;
        end;
    end;

end;


//- - - - - - - - - - - - - MAIN EDIT FUNCTION  - - - - - - - - - - - - - - -
//----------------------------------------------------------------------------
function TGeneric5.Edit: Integer;
//----------------------------------------------------------------------------

// This function is the heart of the property managment for this class

var     // Define some local vars for handling parser results

    ParamPointer: Integer;
    ParamName: String;
    Param: String;

// The Edit function starts where the Parser is presently pointing and
// manages the parsing of the rest of the command line in the parser.

// The DSS executive processes the command verb on the front of the line and
// then passes control to the appropriate Edit function

begin

  // set the present element active
  // and continue parsing with contents of Parser
    ActiveGeneric5Obj := ElementList.Active;
    ActiveCircuit.ActiveCktElement := ActiveGeneric5Obj;
    Result := 0;

    with ActiveGeneric5Obj do
    begin
     // peel off the next token on the edit line
        ParamPointer := 0;
        ParamName := Parser.NextParam;
        Param := Parser.StrValue;

        while Length(Param) > 0 do
        begin
         // Find the index for the CASE statement
         // If property is not named, just increment the index to the next property
            if (Length(ParamName) = 0) then
                Inc(ParamPointer)
            else
                ParamPointer := CommandList.GetCommand(ParamName);

         // Update the PropertyValy for this property
         // Actual index is mapped via PropertyIdxMap array for this class
            if (ParamPointer > 0) and (ParamPointer <= NumProperties) then
                PropertyValue[PropertyIdxMap[ParamPointer]] := Param
            else
                DoSimpleMsg('Unknown parameter "' + ParamName + '" for Generic5 "' + Name + '"', 560);

         // --------------- MAIN CASE STATEMENT ----------------------
            if ParamPointer > 0 then
         // since we used AddProperty function to define properties, have to
         // use PropertyIdxMap to map to the correct Case index
                case PropertyIdxMap[ParamPointer] of
                    0:
                        DoSimpleMsg('Unknown parameter "' + ParamName + '" for Object "' + Class_Name + '.' + Name + '"', 561);
                    1:
                        NPhases := Parser.Intvalue; // num phases
                    2:
                    begin
                        SetBus(1, param);      //'bus1 = 8.1.2.3'
                  //if True then

                    end;

                    3:
                        PresentkV := Parser.DblValue;
                    4:
                    begin
                        kWBase := Parser.DblValue;
                        if (Pmax < 0) or (Pmax > kWBase * 1000) then
                            Pmax := kWBase * 1000;
                        if PQpriority = 1 then
                            Pmax := kWBase * 1000;
                    end;

                    5: ; // Do nothing; read only power factor    := Parser.DblValue;
                    6:
                        InterpretConnection(Parser.StrValue);
                    7:
                        MachineData.kVArating := Parser.DblValue;
            //8: MachineData.Hmass   := Parser.DblValue;
            //9: MachineData.D       := Parser.DblValue;
                    10:
                        P_ref1 := 1000 * Parser.DblValue;  //for phase ctrl unit kW to W
                    11:
                        P_ref2 := 1000 * Parser.DblValue;  //for phase ctrl
                    12:
                        P_ref3 := 1000 * Parser.DblValue;  //for phase ctrl
                    13:
                        V_ref1 := 1000 * Parser.DblValue;  //for phase ctrl unit kV to V
                    14:
                        V_ref2 := 1000 * Parser.DblValue;  //for phase ctrl
                    15:
                        V_ref3 := 1000 * Parser.DblValue;  //for phase ctrl
                    16:
                        MaxSlip := Parser.DblValue;
                    17: ;//InterpretOption(Parser.StrValue);
                    18:
                        YearlyShape := Param;
                    19:
                        DailyDispShape := Param;
                    20:
                        DutyShape := Param;
                    21:
                        DebugTrace := InterpretYesNo(Param);
              {}
                    22:
                        Set_P_Ref(Parser.DblValue);//to norm value W from kW(in script)//for avg ctrl    1000*PrefKw/3;
                    23:
                        Set_Q_Ref(Parser.DblValue);//to VA from kVA(in script)         //for avg ctrl    1000*QrefKVAr/3;
                    24:
                        Cluster_Num := Parser.Intvalue;
                    25:
                        Set_V_Ref(Parser.Dblvalue);//kV  to V                          //for avg ctrl    1000*VrefkV;
                    26:
                        ctrl_mode := Parser.Intvalue;
                ///////////////////////////////////////////
    ///
    ///////////////////////////////////////////
                    27:
                    begin
                        QV_flag := Parser.Intvalue;
                    end;  // QV_flag_0 :=QV_flag
                    28:
                        kcd := Parser.dblvalue;
                    29:
                        kcq := Parser.dblvalue;
                    30:
                        kqi := Parser.dblvalue;
                    31:
                        Q_ref1 := 1000 * Parser.DblValue; //for phase ctrl unit kVar to Var
                    32:
                        Q_ref2 := 1000 * Parser.DblValue; //for phase ctrl
                    33:
                        Q_ref3 := 1000 * Parser.DblValue; //for phase ctrl
                    34:
                    begin
                        Pmax := 1000 * Parser.DblValue; //Pmax has to be less then kW in script
                        PMax_phase := Pmax / fnphases;
                    end;
                    35:
                    begin
                        Pmin := 1000 * Parser.DblValue;  //for phase ctrl
                        PMin_phase := Pmax / fnphases;
                    end;
                    36:
                        PQpriority := Parser.intValue;  //
                    37:
                        Pmpp := 1000 * Parser.DblValue;  //for pmpp kW
                    38:
                        Pfctr1 := Parser.DblValue;  //for pmpp
                    39:
                        Pfctr2 := Parser.DblValue;  //for pmpp
                    40:
                        Pfctr3 := Parser.DblValue; //for pmpp
                    41:
                        Pfctr4 := Parser.DblValue; //for pmpp
                    42:
                        Pfctr5 := Parser.DblValue; //for  pmpp
                    43:
                        Pfctr6 := Parser.DblValue; //for pmpp
                    44:
                        Pbias := 1000 * Parser.DblValue; //for pmpp
                    45:
                        CC_switch := InterpretYesNo(parser.StrValue); //  yes, true, y ,t; or no, false, n, f
                    46:
                        kcq_drp2 := parser.DblValue; //cluster num
                    47:
                        Volt_Trhd := parser.DblValue;
                    48:
                        droop := Parser.intValue;
                else
           // Handle Inherited properties
                    ClassEdit(ActiveGeneric5Obj, ParamPointer - NumPropsThisClass)
                end;

         // ---------------- SIDE EFFECTS CASE STATEMENT ---------------------
         // This case statment handles any side effects from setting a property
         // (for example, from Generator)
            if ParamPointer > 0 then
                case PropertyIdxMap[ParamPointer] of
                    1:
                        SetNcondsForConnection;  // Force Reallocation of terminal info
                    18:
                    begin
                        YearlyShapeObj := LoadShapeClass.Find(YearlyShape);
                        if Assigned(YearlyShapeObj) then
                            with YearlyShapeObj do
                                if UseActual then
                                    SetPowerkW(MaxP);
                    end;
                    19:
                    begin
                        DailyDispShapeObj := LoadShapeClass.Find(DailyDispShape);
                        if Assigned(DailyDispShapeObj) then
                            with DailyDispShapeObj do
                                if UseActual then
                                    SetPowerkW(MaxP);
                    end;
                    20:
                    begin
                        DutyShapeObj := LoadShapeClass.Find(DutyShape);
                        if Assigned(DutyShapeObj) then
                            with DutyShapeObj do
                                if UseActual then
                                    SetPowerkW(MaxP);
                    end;
                else
                end;

          //if Pmpp and fctrs are defined
            if ((ParamPointer >= 37) and (ParamPointer <= 44)) then
            begin
                Update_kWbase_by_Fctrs;// Update Pmax
                                    //will cover direct Pmax input by these
            end;

         // Get next token off Parser and continue editing properties
            ParamName := Parser.NextParam;
            Param := Parser.StrValue;
        end;

     // After editing is complete, the typical next step is to call the RecalcElementData function
     {---------------}
     //if QV_switch = 1 then //
     //begin
          //QV_flag := QV_flag_0;
          //QV_switch := 0;// wait next limit break
     //end;
        Update_PQlimits;
     {----------------}
        RecalcElementData;
        YPrimInvalid := TRUE; // Setting this flag notifies the DSS that something has changed
                           // and the Yprim will have to be rebuilt
    end;

end;

//----------------------------------------------------------------------------
// dont use this 0114-2018 by Ying
//----------------------------------------------------------------------------
function TGeneric5.MakeLike(const OtherIndMach012Name: String): Integer;

// This function should be defined to handle the Like property inherited from
// the base class.

// The function copies the essential properties of another object of this class

var
    OtherIndMach012: TGeneric5Obj;
    i: Integer;

begin
    Result := 0;
   {See if we can find this IndMach012 name in the present collection}
    OtherIndMach012 := Find(OtherIndMach012Name);
    if (OtherIndMach012 <> NIL)   // skip if not found
    then
        with ActiveGeneric5Obj do
        begin
       // You should first set the basic circuit element properties, for example
            if (Fnphases <> OtherIndMach012.Fnphases) then
            begin
                Nphases := OtherIndMach012.Fnphases;
                NConds := Fnphases;  // Forces reallocation of terminal stuff

                Yorder := Fnconds * Fnterms;
                YPrimInvalid := TRUE;
            end;

            PresentkV := OtherIndMach012.PresentkV;
            kWBase := OtherIndMach012.kWBase;

            puRs := OtherIndMach012.puRs;
            puRr := OtherIndMach012.puRr;
            puXr := OtherIndMach012.puXr;
            puXm := OtherIndMach012.puXm;
            puXs := OtherIndMach012.puXs;
            MaxSlip := OtherIndMach012.MaxSlip;

            MachineData.kVArating := OtherIndMach012.MachineData.kVArating;
            MachineData.Hmass := OtherIndMach012.MachineData.Hmass;
            MachineData.D := OtherIndMach012.MachineData.D;

       // Do inherited properties
            ClassMakeLike(OtherIndMach012);

       // Finally initialize all the property value strings to be the same as
       // the copied element
            for i := 1 to ParentClass.NumProperties do
                FPropertyValue^[i] := OtherIndMach012.FPropertyValue^[i];

            Result := 1;
        end
    else
        DoSimpleMsg('Error in Load MakeLike: "' + OtherIndMach012Name + '" Not Found.', 562);

end;

//----------------------------------------------------------------------------
function TGeneric5.Init(Handle: Integer): Integer;
//----------------------------------------------------------------------------

// Optional function if you want to do anything to initialize objects of this class

var
    p: TGeneric5Obj;

begin

    if (Handle = 0) then
    begin  // init all
        p := elementList.First;
        while (p <> NIL) do
        begin
            p.Randomize(0);
            p := elementlist.Next;
        end;
    end
    else
    begin
        Active := Handle;
        p := GetActiveObj;
        p.Randomize(0);
    end;

    DoSimpleMsg('Need to implement TGeneric5.Init', -1);
    Result := 0;

end;

//------------------------- MAIN OBJECT CONSTRUCTOR ---------------------
constructor TGeneric5Obj.Create(ParClass: TDSSClass; const Generic5ObjName: String);
var
    i, j: Integer;
//----------------------------------------------------------------------------
begin
    inherited create(ParClass);
    Name := LowerCase(Generic5ObjName);
    DSSObjType := ParClass.DSSClassType; // Same as Parent Class

     // Set some basic circuit element properties
    Nphases := 3;  // typical DSS default for a circuit element
    Fnconds := 3;  // defaults to delta
    Yorder := 0;  // To trigger an initial allocation
    Nterms := 1;  // forces allocations of terminal quantities
    kWBase := -1;//00; // has to be set in DSS scripts

    YearlyShape := '';
    YearlyShapeObj := NIL;  // if YearlyShapeobj = nil then the load alway stays nominal * global multipliers
    DailyDispShape := '';
    DailyDispShapeObj := NIL;  // if DaillyShapeobj = nil then the load alway stays nominal * global multipliers
    DutyShape := '';
    DutyShapeObj := NIL;  // if DutyShapeobj = nil then the load alway stays nominal * global multipliers

    Debugtrace := FALSE;
    FmonObj := NIL;
    Yorder := Fnterms * Fnconds;
    ShapeIsActual := FALSE;
    Generic5SwitchOpen := FALSE;

    Connection := 1;  // Delta Default

    MachineData.kVGeneratorBase := 12.47;

    MachineData.kVArating := kWBase * 1.2;
    with MachineData do
    begin
        Hmass := 1.0;       //  W-sec/VA rating
        Theta := 0.0;
        w0 := TwoPi * Basefrequency;
        Speed := 0.0;  // relative speed
        dSpeed := 0.0;
        D := 1.0;
        XRdp := 20.0;   // not used for indmach

           // newly added
        Conn := connection;
        NumPhases := Fnphases;
        NumConductors := Fnconds;
    end;

    {---- end note Andres: from dll model ----}

    {Typical machine impedance data}
    puRs := 0.0053;
    puXs := 0.106;
    puRr := 0.007;
    puXr := 0.12;
    puXm := 4.0;

      // Set slip local and make generator model agree
    MaxSlip := 0.1;  // 10% slip limit     - set this before setting slip
      //Slip := -0.007;   // About 1 pu power
    FixedSlip := FALSE;  // Allow Slip to float to match specified power

    InDynamics := FALSE;

     // call the procedure to set the initial property string values
    InitPropertyValues(0);
      //NumOrder := 2;
    NumOrderX := nOrder;//2;// //  system order
    NumOrderY := nOrder; //2;////  system output Y order
      {A,B,C,D, X_var, Y_out_var, V_in_var matrix}
    ReAllocMem(Amm, nOrder * nOrder * Sizeof(Amm^[1]));// dot X = Ax +Bu
    ReAllocMem(Bmn, nOrder * nOrder * Sizeof(Bmn^[1]));// suppose Y and U have the same dimesion. Square
    ReAllocMem(Cnm, nOrder * nOrder * Sizeof(Cnm^[1]));
    ReAllocMem(Dnn, nOrder * nOrder * Sizeof(Dnn^[1]));
    ReAllocMem(X_var, nOrder * Sizeof(X_var^[1]));
    ReAllocMem(dX_vardt, nOrder * Sizeof(dX_vardt^[1]));
    ReAllocMem(X_varn, nOrder * Sizeof(X_varn^[1]));   // for trapezoid integration
    ReAllocMem(dX_vardtn, nOrder * Sizeof(dX_vardtn^[1]));  // for trapezoid integration
    ReAllocMem(Y_out_var, nOrder * Sizeof(Y_out_var^[1]));
    ReAllocMem(V_in_var, nOrder * Sizeof(V_in_var^[1]));
    ReAllocMem(pV_f_cc, nOrder * Sizeof(pV_f_cc^[1]));
    //Allocate ABCDXYV
    {A,B matrix, X_var}  //5 order system
    for i := 1 to nOrder do
    begin
        for j := 1 to nOrder do
        begin
            Amm^[(i - 1) * nOrder + j] := 0.0;//CMPLX(0.0, 0.0);
              //if j=i then
              //     Amm^[(i-1)*nOrder +j] := 1;//Amm := 0;
        end;
        for j := 1 to nOrder do
        begin
            Bmn^[(i - 1) * nOrder + j] := 0.0;//CMPLX(0.0, 0.0);
            if j = i then
                Bmn[(i - 1) * nOrder + j] := 1;
        end;
        X_var^[i] := 0.0;//CMPLX(0.0, 0.0);
        dX_vardt^[i] := 0.0;// derivatives
        X_varn^[i] := 0.0;// for trapezoid
        dX_vardtn^[i] := 0.0;// derivatives
    end;
    {C,D Matrix, Y, V}
    for i := 1 to nOrder do
    begin
        for  j := 1 to nOrder do
        begin
            Dnn[(i - 1) * nOrder + j] := 0.0;//CMPLX(0.0, 0.0);
        end;
        for j := 1 to nOrder do
        begin
            Cnm[(i - 1) * nOrder + j] := 0.0;//CMPLX(0.0, 0.0);
            if i = j then
                Cnm[(i - 1) * nOrder + j] := 1;
        end;
        Y_out_var[i] := 0.0;//CMPLX(0.0, 0.0);
        V_in_var[i] := 0.0;//CMPLX(0.0, 0.0);
        pV_f_cc[i] := 0.0;
    end;
    P_ref := 0;
    V_ref := 1;
    Id := 0;
    Iq := 0;//default current
    Id1 := 0;
    Iq1 := 0;
    Id2 := 0;
    Iq2 := 0;
    Id3 := 0;
    Iq3 := 0;//
     {}
    kcd := 0.1;
    kcq := 0.1;
    kqi := 0.1; //for local control gain in vi1, vi2
    Volt_Trhd := 0.0;
     //Id_ref := 1;
     //Iq_ref := 0;
    Cluster_Num := 0;//by default.
     // Update anything that has to be calculated from property values
    DQDV := 1;//
    ctrl_mode := 0;// avg contrl by default
    QV_flag := 0;
     //QV_flag_0 := QV_flag;
     {------------------}
     //PQ max
    PMax := -1; // Activity power output limit  MachineData.kVArating :=  1.2*kWbase; Pmax, Smax
    PMax_phase := PMax / fnphases; //limit per phase
    PMin := 0;  //(0, default)
    Pmin_phase := PMin / fnphases; //
    Qmax := 1000 * MachineData.kVArating; //Reactive power output limit
    Qmax_phase := Qmax / fnphases;
    Qmin := -Qmax; //(-Qmax, default)
    Qmin_phase := Qmin / fnphases; //
    PQpriority := 1;//P priority
    Pmpp := 1;//Pmpp, default value is 1.0;
    Pbias := 0; //Pbias, default value is 0.0;
    Pfctr1 := 1;//factors, default value all are 1.0;
    Pfctr2 := 1;
    Pfctr3 := 1;
    Pfctr4 := 1;
    Pfctr5 := 1;
    Pfctr6 := 1;
     {------------------}
    kcq_drp2 := 0;
    CC_switch := FALSE;
    flag_dyna_Id_chg := FALSE;

    z_dfs_plot := 0.0;

    RecalcElementData;

end;


//----------------------------------------------------------------------------
destructor TGeneric5Obj.Destroy;
//----------------------------------------------------------------------------

// Free everything here that needs to be freed
// If you allocated anything, dispose of it here

begin

    //A, B matrix
    if Assigned(Amm) then
        ReallocMem(Amm, 0);
    if Assigned(Bmn) then
        Reallocmem(Bmn, 0);
    if Assigned(Cnm) then
        Reallocmem(Cnm, 0);
    if Assigned(Dnn) then
        Reallocmem(Dnn, 0);
    if Assigned(X_var) then
        Reallocmem(X_var, 0);
    if Assigned(dX_vardt) then
        Reallocmem(dX_vardt, 0);
    if Assigned(X_varn) then
        Reallocmem(X_varn, 0);
    if Assigned(dX_vardtn) then
        Reallocmem(dX_vardtn, 0);
    if Assigned(Y_out_var) then
        Reallocmem(Y_out_var, 0);
    if Assigned(V_in_var) then
        Reallocmem(V_in_var, 0);
    ReAllocMem(pV_f_cc, 0);

    inherited Destroy;   // This will take care of most common circuit element arrays, etc.

end;


//----------------------------------------------------------------------------
procedure TGeneric5Obj.RecalcElementData;
//----------------------------------------------------------------------------

var
    Rs, Xs,
    Rr, Xr,
    Xm, ZBase: Double;
    modetest: Boolean;
    numPhase, DotPos: Integer;
    strtemp: String;
begin

    with MachineData do
    begin
        ZBase := Sqr(kVGeneratorBase) / kVArating * 1000.0;
        Conn := connection;
        NumPhases := Fnphases;
        NumConductors := Fnconds;
    end;


    Rs := puRs * ZBase;
    Xs := puXs * ZBase;
    Rr := puRr * ZBase;
    Xr := puXr * ZBase;
    Xm := puXm * ZBase;
    Zs := Cmplx(Rs, Xs);
    Zm := Cmplx(0.0, Xm);
    Zr := Cmplx(Rr, Xr);

    Xopen := Xs + Xm;
    Xp := Xs + (Xr * Xm) / (Xr + Xm);
    Zsp := Cmplx(Rs, Xp);
    //Yeq := Cinv(Zsp);   // for Yprim  for dynamics
    //Yeq := Cmplx(1.0/ZBase, -0.5/Zbase);   // vars are half the watts
    Yeq := Cmplx(0.0, -1.0 / ZBase);   // vars only for power flow
    T0p := (Xr + Xm) / (MachineData.w0 * Rr);

 //   dSdP := Compute_dSdP;

    Is1 := CZERO;
    V1 := CZERO;
    Is2 := CZERO;
    V2 := CZERO;

    FirstIteration := TRUE;

    Reallocmem(InjCurrent, SizeOf(InjCurrent^[1]) * Yorder);

    SetNominalPower;
    ///////////////////////////////////////////
    /// contrl mode
    ///    ctrl_mode =0; phases = 3;  // pos avg control---p_ref, V_ref, Q_ref
    ///    ctrl_mode =1; phases = 1; bus1 = 452.1;      ---p_ref1, V_ref1, Q_ref1
    ///    ctrl_mode =2; phases = 1; bus1 = 452.2;      ---p_ref2, V_ref2, Q_ref2
    ///    ctrl_mode =3; phases = 1; bus1 = 452.3;      ---p_ref3, V_ref3, Q_ref3
    ///    ctrl_mode =4; phases = 3; bus1 = 452.2;      ---p_ref1,2,3, V_ref1,2,3, Q_ref1,2,3
    ///
    ///////////////////////////////////////////
    modetest := FALSE;
    if (((ctrl_mode = 0) or (ctrl_mode = 4)) and (fnphases = 3)) then
        modetest := TRUE
    else
    if (fnphases = 1) then
    begin
        if ((ctrl_mode = 1) or (ctrl_mode = 2) or (ctrl_mode = 3)) then
        begin
            strtemp := FirstBus;  //only one
            DotPos := Pos('.', strtemp);
            if DotPos <> 0 then
            begin
                numphase := sysutils.StrToInt(Trim(Copy(strtemp, DotPos + 1, 1))); // Bus Name . node Num
                if numphase = ctrl_mode then
                    modetest := TRUE
            end;
        end;
    end;
    if modetest = FALSE then
        DoSimpleMsg('ctrl_mode and bus node connection dont match, see help for generic5.ctrl_mode', 561);
    //////////////////////////////////////////////
    //if cluster_num >= 1 then      // assign the virtue leader to this DG
     //FMonObj := ActiveCircuit.Fmonitors.Get(cluster_num);
     //if function 'get' fails , return nil
    //////////////////////////////////////////////
    if CompareText(YearlyShape, 'none') = 0 then
        YearlyShape := '';
    if CompareText(DailyDispShape, 'none') = 0 then
        DailyDispShape := '';
    if CompareText(DutyShape, 'none') = 0 then
        DutyShape := '';

    if YearlyShapeObj = NIL then
        if Length(YearlyShape) > 0 then
            DoSimpleMsg('WARNING! Yearly load shape: "' + YearlyShape + '" Not Found.', 563);
    if DailyDispShapeObj = NIL then
        if Length(DailyDispShape) > 0 then
            DoSimpleMsg('WARNING! Daily load shape: "' + DailyDispShape + '" Not Found.', 564);
    if DutyShapeObj = NIL then
        if Length(DutyShape) > 0 then
            DoSimpleMsg('WARNING! Duty load shape: "' + DutyShape + '" Not Found.', 565);

    SpectrumObj := SpectrumClass.Find(Spectrum);
    if SpectrumObj = NIL then
        DoSimpleMsg('ERROR! Spectrum "' + Spectrum + '" Not Found.', 566);

    if DebugTrace then
        InitTraceFile;
end;

 {
Procedure TGeneric5Obj.CalcABMatrix  ;
//var
//      i,j     :Integer;
begin
       //this is useless. All things is to be done in updateabcd
end;


procedure TGeneric5Obj.InterpretOption(s: String);
begin
     Case Uppercase(s)[1] of
       'F': Fixedslip := TRUE;
       'V': Fixedslip := FALSE;
     Else

     End;
end;

//---------------------------------------------------------------------------- }
procedure TGeneric5Obj.SetPowerkW(const PkW: Double);
begin
    kWBase := PkW;
end;

procedure TGeneric5Obj.Set_PresentkV(const Value: Double);
begin
    with MachineData do
    begin
        kVGeneratorBase := Value;
        case FNphases of
            2, 3:
                VBase := kVGeneratorBase * InvSQRT3x1000;
        else
            VBase := kVGeneratorBase * 1000.0;
        end;
    end;
end;

function TGeneric5Obj.Get_PresentkV: Double;
begin
    Result := MachineData.kVGeneratorBase;
end;

//----------------------------------------------------------------------------
//--------------------- MAIN CALC ROUTINES -----------------------------------

//----------------------------------------------------------------------------
procedure TGeneric5Obj.Integrate;
//----------------------------------------------------------------------------

var
    h2: Double;

begin
    if ctrl_mode = 0 then
    begin
        with  ActiveCircuit.Solution.Dynavars do
        begin
            if IterationFlag = 0 then
            begin  // on predictor step
                Idn := Id;
                Iqn := Iq;
                dIddtn := dIddt;
                dIqdtn := dIqdt;
                vi1n := vi1;
                vi2n := vi2;
                dvi1dtn := dvi1dt;
                dvi2dtn := dvi2dt;
            end;

            update_system_abcd; //vi1, vi2 calculation

            h2 := h * 0.5;

            Id_ref := kcd * P_ref / V_DG;//active

            Iq_ref := Q_DG / V_DG; //V_ref ~= 1;  reactive
          //vi1 :=    kcq* (Iq_ref - Iq);
            DPx := P_ref - P_DG;
            vi1 := 1 * kcd * DPx / V_DG;//+ kcq* (Iq_ref - Iq);//+ //active + additional control
          //vi2 := kcd* (Id_ref - Id); //reactive
            dvi1dt := kcd * (DPx);
          //dvi2dt :=  -kcd* (V_ref-V_DG) ;    //voltage droop control
            if QV_flag = 1 then
                vi2 := kcq * (V_ref - V_DG)     //voltage droop control
            else
                vi2 := kqi * (Q_ref - Q_DG);
          {--------------------------------------------}


            dIddt := vi1;//1; //active P
            dIqdt := vi2;//2; //reactive Q

            Id := Idn + h2 * (dIddt + dIddtn);
            Iq := Iqn + h2 * (dIqdt + dIqdtn);
        end;
    end;
end;

{-------------------------------------------------------------------------------}
{integrate with ABCD}
procedure TGeneric5Obj.IntegrateABCD;
//----------------------------------------------------------------------------
var
    h2: Double;
    i, j: Integer;
begin
    if ActiveCircuit.Solution.Dynavars.IterationFlag = 0 then
    begin
        for i := 1 to numOrderX do
        begin
            X_varn^[i] := X_var^[i];
            dX_vardtn^[i] := dX_vardt^[i];
        end;
    end;

    update_system_abcd; //Matrix ABCD calculation if they are state-dependant
    update_controlinput; //vi1, vi2 calculation,
                                // co control strategies from network vfi can be done here
            //dX_vardt calculation
    for i := 1 to numOrderX do //  numOrderX, numOrderY should be less than norder 5
    begin
        dX_vardt^[i] := 0.0;
        for j := 1 to numOrderY do
        begin
            dX_vardt^[i] := dX_vardt^[i] + Amm^[norder * (i - 1) + j] * X_var^[j] + Bmn^[norder * (i - 1) + j] * V_in_var^[j];
                                          //cooperate control if exist is involved in
        end;

    end;

            // Trapezoidal Integration
    h2 := ActiveCircuit.Solution.Dynavars.h * 0.5;
    for i := 1 to numorderX do
    begin
        X_var[i] := X_varn[i] + h2 * (dX_vardtn[i] + dX_vardt[i]);
    end;
            {----------------}
            //Y=CX to be added
            {----------------}
         ///
         ///  the following is to connect with calcDynamic or CalcDynamicVIabc
         ///  because Id, Iq; Id1, Iq1, Id2, Iq2, Id3, Iq3 will be used there
    if ctrl_mode = 0 then //pos seq control
    begin
        Id := X_var[1];//can be put in calcdyna, so the integrate is just for X_var
        Iq := X_var[2];
    end
    else   // all other ctrl_mode's are phase control modes
    begin
        Id1 := X_var[1];//1st phase, or the only phase if fnphases=1
        Iq1 := X_var[2];//can be put in calcdyna in futher, so the integrate is just for X_var
        Id2 := X_var[3];//2nd phase; zero if single phase
        Iq2 := X_var[4];
        Id3 := X_var[5];//3rd phase; zero if single phase
        Iq3 := X_var[6];
    end;
end;

{-------------------------------------------------------------------------------}
//This part deals with the control input,  is based on the voltage measurement
procedure TGeneric5Obj.update_controlInput;
var
    j: Integer;
    temp_pref, temp_qref, temp_vref, Pref3: Double;
begin
    //Update_PQlimits;
    ///////////////////////////////////
    //local control input and alpha gradient calculation
    ///////////////////////////////////
    //gradient, gradient1, gradient2, gradient3
    //   gradient will be calculated in FMonitor because of Bii, Q_Di etc
    //calculate_gradient; //alpha, and gradients，
                        //V_DG, Q_DG have been updated either in 'init' or in 'calcdynamic'

    if ctrl_mode = 0 then //pos seq control mode
    begin
        //Id
        // P and Q control
        {
        //Iq
        if QV_flag=1 then
          vi2 := kcq* (V_ref - V_DG) //reactive V_ref control
        else
          vi2 := kqi* (Q_ref - Q_DG); //reactive Q_ref control
        }
        // vi1, vi2 local gradient
        //  vi1, vi2 =0, local gradient calculated outside
        vi1 := 0;
        vi2 := 0;    // local gradient calculated IN fMONITOR Node
        {---if in curtailment P_ref has to be changed here-----}
        if (ActiveCircuit.Solution.bCurtl = TRUE) and (FmonObj.ld_fm_info[0].b_ctrl_hghst = TRUE) then
                        //if (ActiveCircuit.Solution.bCurtl=true) then // this will cause oscillation
        begin
            Pref3 := V_DG * Id; //Here, P_ref will never go out of limits.
                                        //if cuitailment is needed, update P_ref here; then vi1 will be 0
                 //check limits
            if Pref3 > Pmax then
            begin
                Pref3 := Pmax; //set real power change during the simulation
            end
            else
            if Pref3 < Pmin then
            begin
                Pref3 := Pmin;
            end;
            P_ref := Pref3 / 3.0;
        end;
        {--use vi1 to follow p_ref--}

        DPx := fnphases * P_ref - P_DG;
        vi1 := 100 * kcd * DPx / V_DG;  //pref control is 100 times faster than Curtailment
        //update V_in_var
        V_in_var^[1] := vi1;
        V_in_var^[2] := vi2;

    end
    else
    begin //phases control mode

        if fnphases = 3 then
        begin
        //12
            DPx := P_ref1 - P_DG1;
            vi1 := kcd * DPx / V_DG1;
              //Iq
            if QV_flag = 1 then
            begin
                if cc_switch = FALSE then    //droop
                    vi2 := kcq * (V_ref1 - V_DG1) //reactive V_ref control
                  //gradient
                else
                    vi2 := Qmax_phase / V_DG1 * (-kcq * Gradient1);
                if ((Q_DG1 >= Qmax_phase) or (Q_DG1 <= Qmin_phase)) then  // switch control mode to Q_ref control
                begin
                    //QV_flag := 0;
                    if (Q_DG1 >= Qmax_phase) then
                    begin
                        Q_ref1 := Qmax_phase; // set Q_ref
                        Q_ref2 := Qmax_phase; // set Q_ref
                        Q_ref3 := Qmax_phase; // set Q_ref
                    end
                    else
                    begin
                        Q_ref1 := Qmin_phase;
                        Q_ref2 := Qmin_phase;
                        Q_ref3 := Qmin_phase;
                    end;
                    vi2 := kqi * (Q_ref1 - Q_DG1); //reactive Q_ref control
                end
            end
            else
                vi2 := kqi * (Q_ref1 - Q_DG1); //reactive Q_ref control
              //update V_in_var
            V_in_var^[1] := vi1;
            V_in_var^[2] := vi2;
        //34
            DPx := P_ref2 - P_DG2;
            vi1 := kcd * DPx / V_DG2;
              //Iq
            if QV_flag = 1 then
            begin
                if cc_switch = FALSE then    //droop
                    vi2 := kcq * (V_ref2 - V_DG2) //reactive V_ref control
                  //gradient
                else
                    vi2 := Qmax_phase / V_DG2 * (-kcq * Gradient2);
                if ((Q_DG2 >= Qmax_phase) or (Q_DG2 <= Qmin_phase)) then  // switch control mode to Q_ref control
                begin
                    //QV_flag:=0;
                    if (Q_DG2 >= Qmax_phase) then
                    begin
                        Q_ref1 := Qmax_phase; // set Q_ref
                        Q_ref2 := Qmax_phase; // set Q_ref
                        Q_ref3 := Qmax_phase; // set Q_ref
                    end
                    else
                    begin
                        Q_ref1 := Qmin_phase;
                        Q_ref2 := Qmin_phase;
                        Q_ref3 := Qmin_phase;
                    end;
                    vi2 := kqi * (Q_ref2 - Q_DG2); //reactive Q_ref control
                end
            end
            else
                vi2 := kqi * (Q_ref2 - Q_DG2); //reactive Q_ref control
              //update V_in_var
            V_in_var^[3] := vi1;
            V_in_var^[4] := vi2;
        //56
            DPx := P_ref3 - P_DG3;
            vi1 := kcd * DPx / V_DG3;
              //Iq
            if QV_flag = 1 then
            begin
                if cc_switch = FALSE then    //droop
                    vi2 := kcq * (V_ref3 - V_DG3) //reactive V_ref control
                  //gradient
                else
                    vi2 := Qmax_phase / V_DG3 * (-kcq * Gradient3);
                if ((Q_DG3 >= Qmax_phase) or (Q_DG3 <= Qmin_phase)) then  // switch control mode to Q_ref control
                begin
                    //QV_flag := 0;
                    if (Q_DG3 >= Qmax_phase) then
                    begin
                        Q_ref1 := Qmax_phase; // set Q_ref
                        Q_ref2 := Qmax_phase; // set Q_ref
                        Q_ref3 := Qmax_phase; // set Q_ref
                    end
                    else
                    begin
                        Q_ref1 := Qmin_phase;
                        Q_ref2 := Qmin_phase;
                        Q_ref3 := Qmin_phase;
                    end;
                    vi2 := kqi * (Q_ref3 - Q_DG3); //reactive Q_ref control
                end
            end
            else
                vi2 := kqi * (Q_ref3 - Q_DG3); //reactive Q_ref control
              //update V_in_var
            V_in_var^[5] := vi1;
            V_in_var^[6] := vi2;
        end
        else
        if fnphases = 1 then
        begin
              //choose ref
            case ctrl_mode of
                1:
                begin
                    temp_pref := P_ref1;
                    temp_qref := q_ref1;
                    temp_vref := v_ref1;
                end;
                2:
                begin
                    temp_pref := P_ref2;
                    temp_qref := q_ref2;
                    temp_vref := v_ref2;
                end;
                3:
                begin
                    temp_pref := P_ref3;
                    temp_qref := q_ref3;
                    temp_vref := v_ref3;
                end;
            end;

            DPx := temp_pref - P_DG1;
            vi1 := kcd * DPx / V_DG1;
              //Iq
            if QV_flag = 1 then
            begin
                if cc_switch = FALSE then    //droop
                    vi2 := kcq * (temp_vref - V_DG) //reactive V_ref control
                else
                    vi2 := Qmax_phase / V_DG1 * (-kcq * Gradient1);
                if ((Q_DG1 >= Qmax_phase) or (Q_DG1 <= Qmin_phase)) then  // switch control mode to Q_ref control
                begin
                    //QV_flag := 0;
                    if (Q_DG1 >= Qmax_phase) then
                        temp_qref := Qmax_phase // set Q_ref
                    else
                        temp_qref := Qmin_phase;
                    //
                    vi2 := kqi * (temp_qref - Q_DG); //reactive Q_ref control
                    //send Qref back
                    //q_ref1 := temp_qref;
                    //q_ref2 := temp_qref;
                    //q_ref3 := temp_qref;
                end
            end
            else
                vi2 := kqi * (temp_qref - Q_DG); //reactive Q_ref control
              //update V_in_var
            V_in_var^[1] := vi1;
            V_in_var^[2] := vi2;
        end;

    end;
    {--------------------------------}
    // cooperate part is done here
    //pVinput^[j];
    update_pV_f_CC; //update pV_f_CC which is cooperate control
    {--------------------------------}
//implement cooperate control
    for j := 1 to numOrderX do
        V_in_var^[j] := V_in_var^[j] + pV_f_CC^[j];
end;

procedure TGeneric5Obj.update_pV_f_CC_M2;  //for power flow
var
    j: Integer;
    num_vleader: Integer;
    Bii: Double;
begin
    if cc_switch = FALSE then
    begin
        for j := 1 to numOrderX do
            pV_f_CC^[j] := 0.0;
        exit;
    end;

            //avg ctrl, under V120, I120
      //////////////////////////////////
    if FmonObj <> NIL then
    begin
 //try
        num_vleader := 1;
            /////////////////////////////////
        if ctrl_mode = 0 then
        begin
                       //u = gradient + pV_f_CC; pV_f_CC = -alpha + sum(alpha_j)
            Bii := ActiveCircuit.Solution.NodeYii^[NodeRef^[1]].im;
                        // Q ctrl with v_ref
                      //  pV_f_CC^[2] := FmonObj.Calc_Alpha_M2(ndNumincluster,0,NodeRef^[1],Bii,kcq,Volt_Trhd); // for dIddt, diqdt
                        // Q ctrl with loss
                        //pV_f_CC^[2] := FmonObj.Calc_Alpha_L(ndNumincluster,0,NodeRef^[1],Bii,kcq,Volt_Trhd);
            pV_f_CC^[2] := FmonObj.Calc_Alpha_LnM2(ndNumincluster, 0, NodeRef^[1], Bii, kcq, Volt_Trhd);
                        // pV_f_CC^[2] := alpha * Qmax / v ;
                        //P ctrl
                        //pV_f_CC^[1] := FmonObj.Calc_AlphaP(ndNumincluster,0); // for dIddt, diqdt
            pV_f_CC^[1] := 0;
        end
                  // phases control
        else
        begin
            if fnphases = 3 then
            begin
                pV_f_CC^[6] := 0.0;
                        //u = gradient + pV_f_CC; pV_f_CC = -alpha + sum(alpha_j)
                Bii := ActiveCircuit.Solution.NodeYii^[NodeRef^[1]].im;
                pV_f_CC^[2] := FmonObj.Calc_Alpha_M2(ndNumincluster, 1, NodeRef^[1], Bii, kcq, Volt_Trhd);
                        //pV_f_CC^[2] := FmonObj.Calc_Alpha_L(ndNumincluster,1,NodeRef^[1],Bii,kcq,Volt_Trhd);
                        //pV_f_CC^[2] := FmonObj.Calc_Alpha_LnM2(ndNumincluster,1,NodeRef^[1],Bii,kcq,Volt_Trhd);
                pV_f_CC^[1] := FmonObj.Calc_AlphaP(ndNumincluster, 1);
                Bii := ActiveCircuit.Solution.NodeYii^[NodeRef^[2]].im;
                pV_f_CC^[4] := FmonObj.Calc_Alpha_M2(ndNumincluster, 2, NodeRef^[2], Bii, kcq, Volt_Trhd);
                        //pV_f_CC^[4] := FmonObj.Calc_Alpha_L(ndNumincluster,2,NodeRef^[2],Bii,kcq,Volt_Trhd);
                        //pV_f_CC^[4] := FmonObj.Calc_Alpha_LnM2(ndNumincluster,2,NodeRef^[2],Bii,kcq,Volt_Trhd);
                pV_f_CC^[3] := FmonObj.Calc_AlphaP(ndNumincluster, 2);
                Bii := ActiveCircuit.Solution.NodeYii^[NodeRef^[3]].im;
                pV_f_CC^[6] := FmonObj.Calc_Alpha_M2(ndNumincluster, 3, NodeRef^[3], Bii, kcq, Volt_Trhd);
                        //pV_f_CC^[6] := FmonObj.Calc_Alpha_L(ndNumincluster,3,NodeRef^[3],Bii,kcq,Volt_Trhd);
                        //pV_f_CC^[6] := FmonObj.Calc_Alpha_LnM2(ndNumincluster,3,NodeRef^[3],Bii,kcq,Volt_Trhd);
                pV_f_CC^[5] := FmonObj.Calc_AlphaP(ndNumincluster, 3);
                        //pV_f_CC[1-6]； // for dIddt1, diqdt1,dIddt2, diqdt2,dIddt3, diqdt3
            end
            else
            if fnphases = 1 then
            begin
                        //if ctrl_mode=1 then
                Bii := ActiveCircuit.Solution.NodeYii^[NodeRef^[1]].im;
                pV_f_CC^[2] := FmonObj.Calc_Alpha_M2(ndNumincluster, ctrl_mode, NodeRef^[1], Bii, kcq, Volt_Trhd); // for dIddt1, diqdt1
                        //pV_f_CC^[2] :=  FmonObj.Calc_Alpha_L(ndNumincluster,ctrl_mode,NodeRef^[1],Bii,kcq,Volt_Trhd); // for dIddt1, diqdt1
                        //pV_f_CC^[2] :=  FmonObj.Calc_Alpha_LnM2(ndNumincluster,ctrl_mode,NodeRef^[1],Bii,kcq,Volt_Trhd);
                pV_f_CC^[1] := FmonObj.Calc_AlphaP(ndNumincluster, ctrl_mode);
            end;
        end;
    end;
end;

procedure TGeneric5Obj.update_pV_f_CC; //used in dynamic mode to update alpha
var
    p_mode,
    j,
    num_vleader: Integer;
    Bii,
    us_i, ul_i: Double;
begin
    if cc_switch = FALSE then    //no control at all   //local gradient control will be set by communication matrix
    begin
        for j := 1 to numOrderX do
            pV_f_CC^[j] := 0.0;
        exit;
    end;

            //avg ctrl, under V120, I120
      //////////////////////////////////
    if FmonObj <> NIL then
    begin
 //try
        num_vleader := 1;
            /////////////////////////////////
        if ctrl_mode = 0 then
        begin
            p_mode := 0;
            if fmonobj <> NIL then
                p_mode := fmonobj.Get_P_mode;
             //u = gradient + pV_f_CC; pV_f_CC = -alpha + sum(alpha_j)
            Bii := ActiveCircuit.Solution.NodeYii^[NodeRef^[1]].im;

            if ActiveCircuit.Solution.DynaVars.SolutionMode = DYNAMICMODE then
            begin
                    //Ip control
                if FmonObj.ld_fm_info[0].b_Curt_Ctrl = TRUE then // curtailment algorithm
                begin
                    ul_i := FmonObj.Calc_ul_P(ndNumincluster, 0);
                    us_i := kcd * FmonObj.Calc_Gradient_ct_P(ndNumincluster, 0);
                    GradientP := us_i;
                    if cc_switch = FALSE then   //local
                        pV_f_CC^[1] := 0.0
                    else
                    begin
                        pV_f_CC^[1] := ul_i + us_i;
                        pV_f_CC^[1] := pV_f_CC^[1] * Pmax / v_DG;
                    end;
                end;

                    //if pMode then

                if (p_mode = 1) and (cc_switch = TRUE) then //if delta P = p_trans_ref - p_trans
                begin //balance p_trans
                    pV_f_CC^[1] := FmonObj.Calc_AlphaP(ndNumincluster, 0);//new alfa_p
                    pV_f_CC^[1] := pV_f_CC^[1] - AlphaP; //derivative of alfa_p
                           //use us_i to calculate the frequncy
                    us_i := -FmonObj.omg_fm; //frequency droop
                    pV_f_CC^[1] := (pV_f_CC^[1] + us_i) * Pmax / v_DG; // derivative of Ip in dynamic mode,
                           //use us_i to
                end;

                    //Iq control
                ul_i := FmonObj.Calc_fm_ul_0(ndNumincluster, 0, NodeRef^[1], Bii, kcq, Volt_Trhd);
                us_i := FmonObj.Calc_fm_us_0(ndNumincluster, 0, NodeRef^[1], Bii, kcq, Volt_Trhd);
                Gradient := us_i;

                if FmonObj.ld_fm_info[0].b_Curt_Ctrl = FALSE then
                begin // if curtailment for this cluster is off

                end
                else
                begin // if curtailment for this cluster is on
                        //Q will try to boost the voltage while P is decreasing
                    if (ActiveCircuit.Solution.bCurtl = TRUE) and (Gradient = 0.0) then
                        us_i := -GradientP * Pmax / Qmax;
                end;


                if cc_switch = FALSE then   //local
                begin
                    pV_f_CC^[2] := us_i;
                end
                else
                begin  // cc_switch is on
                    pV_f_CC^[2] := ul_i + us_i; //cc  //attack comes in ul_i (FmonObj.Calc_fm_ul_0)
                end;
                pV_f_CC^[2] := pV_f_CC^[2] * Qmax / v_DG;

            end
            else  //power flow
            begin
                    //alphaP: p ratio

                    //if pMode then
                if (p_mode = 1) or (FmonObj.ld_fm_info[0].b_Curt_Ctrl = TRUE) then
                    pV_f_CC^[1] := FmonObj.Calc_AlphaP(ndNumincluster, 0)
                else
                    pV_f_CC^[1] := 0.0;
                    //alpha : q ratio
                pV_f_CC^[2] := FmonObj.Calc_Alpha_M2(ndNumincluster, 0, NodeRef^[1], Bii, kcq, Volt_Trhd); // for dIddt, diqdt

            end;
        end;
    end;

end;

procedure TGeneric5Obj.InfoPublish;
//var
//  j : integer;
begin
    Update_PQlimits;
    if FmonObj <> NIL then
    begin
        with FmonObj.pNodeFMs^[NdNuminCluster] do
        begin
            case ctrl_mode of
                1:
                begin
                    vl_V1 := V_DG1;//Phase A or the first phase if there are less than 3 phases
                    vl_P_DG1 := P_DG1;
                    vl_Q_DG1 := Q_DG1;
                    //vl_Alpha1_dg := Alpha1;
                    //vl_AlphaP1_dg := AlphaP1;
                    vl_V_ref1_dg := V_ref1;
                end;
                2:
                begin
                    vl_V2 := V_DG2;//Phase B if exists
                    vl_P_DG2 := P_DG2;
                    vl_Q_DG2 := Q_DG2;
                    //vl_Alpha2_dg := Alpha2;
                    //vl_AlphaP2_dg := AlphaP2;
                    vl_V_ref2_dg := V_ref2;
                end;
                3:
                begin
                    vl_V3 := V_DG3;//Phase c if exists
                    vl_P_DG3 := P_DG3;
                    vl_Q_DG3 := Q_DG3;
                    //vl_Alpha3_dg := Alpha3;
                    //vl_AlphaP3_dg := AlphaP3;
                    vl_V_ref3_dg := V_ref3;

                end;
                0:
                begin
                    vl_V := V_DG;  //0 seq    , will be used in FmonObj.Agnt_smpl
                    vl_P_DG := P_DG;
                    vl_Q_DG := Q_DG;
                    //
                    alpha := Q_DG / Qmax;
                    vl_alpha_dg := alpha;  // update first, will be used in FmonObj.Agnt_smpl
                    //P control
                    alphap := p_dg / Pmax;
                    vl_alphaP_dg := alphaP;
                    //
                    vl_V_ref_dg := V_ref;
                    if ActiveCircuit.Solution.DynaVars.SolutionMode = DYNAMICMODE then
                    begin
                        z_dfs_plot := z_dfs; // defense value
                    end;
                end;
                4:
                begin
                    vl_V1 := V_DG1;//Phase A or the first phase if there are less than 3 phases
                    vl_P_DG1 := P_DG1;
                    vl_Q_DG1 := Q_DG1;
                    vl_V2 := V_DG2;//Phase B if exists
                    vl_P_DG2 := P_DG2;
                    vl_Q_DG2 := Q_DG2;
                    vl_V3 := V_DG3;//Phase c if exists
                    vl_P_DG3 := P_DG3;
                    vl_Q_DG3 := Q_DG3;
                    vl_V_ref1_dg := V_ref1;
                    vl_V_ref2_dg := V_ref2;
                    vl_V_ref3_dg := V_ref3;

                    //vl_Alpha1_dg := Alpha1;
                    //vl_AlphaP1_dg := AlphaP1;
                    //vl_V_ref1_dg := V_ref1;
                    //vl_Alpha2_dg := Alpha2;
                    //vl_AlphaP2_dg := AlphaP2;
                    //vl_V_ref2_dg := V_ref2;
                    //vl_Alpha3_dg := Alpha3;
                    //vl_AlphaP3_dg := AlphaP3;
                    //vl_V_ref3_dg := V_ref3;
                end;
            end;
            vl_Qmax_dg := Qmax;
            vl_Qmax_phase_dg := Qmax_Phase;
            vl_Pmax_dg := Pmax;
            vl_Pmax_phase_dg := Pmax_Phase;
            vl_CC_switch_dg := CC_switch;
            vl_QV_flag_dg := QV_flag;
            vl_kcd_dg := kcd;
            vl_kcq_dg := kcq;
            vl_volt_thrd_dg := Volt_Trhd;
        end;
    end;
    if FmonObj2 <> NIL then
    begin
         {with FmonObj2.pNodeFMs^[NdNuminCluster2] do
         begin

          vl_V := V_DG;
          vl_P_DG := P_DG;
          vl_Q_DG := Q_DG;
          vl_V1 := V_DG1;//Phase A or the first phase if there are less than 3 phases
          vl_P_DG1 := P_DG1;
          vl_Q_DG1 := Q_DG1;
          vl_V2 := V_DG2;//Phase B if exists
          vl_P_DG2 := P_DG2;
          vl_Q_DG2 := Q_DG2;
          vl_V3 := V_DG3;//Phase c if exists
          vl_P_DG3 := P_DG3;
          vl_Q_DG3 := Q_DG3;
          vl_Qmax_dg := Qmax;
          vl_Qmax_phase_dg := Qmax_Phase;
          vl_Pmax_dg := Pmax;
          vl_Pmax_phase_dg := Pmax_Phase;
          vl_Alpha_dg := alpha;
          vl_Alpha1_dg := Alpha1;
          vl_Alpha2_dg := Alpha2;
          vl_Alpha3_dg := Alpha3;
          vl_AlphaP_dg := alphaP;
          vl_AlphaP1_dg := AlphaP1;
          vl_AlphaP2_dg := AlphaP2;
          vl_AlphaP3_dg := AlphaP3;
          vl_V_ref_dg := V_ref;
          vl_V_ref1_dg := V_ref1;
          vl_V_ref2_dg := V_ref2;
          vl_V_ref3_dg := V_ref3;
          vl_CC_switch_dg := CC_switch;
          vl_QV_flag_dg := QV_flag;

          end; }
    end;

end;

procedure TGeneric5Obj.Set_P_ref(PrefKw: Double);
begin
    P_ref := 1000 * prefKw / fnphases;   //nphases
    P_ref1 := P_ref;
    P_ref2 := P_ref;
    P_ref3 := P_ref;
    if prefKw > kWbase then
        DoSimpleMsg('P ref should be leq than kW', 562);
    if ActiveCircuit.Solution.DynaVars.SolutionMode = DYNAMICMODE then //if P_ref changed in the dynamic simulation
    begin                                                              //The sudden change of Id has to be applied
        flag_dyna_Id_chg := TRUE;
    end;
    //
end;

procedure TGeneric5Obj.Set_Q_Ref(QrefkVAr: Double);
begin
    //
    Q_ref := 1000 * QrefKVAr / fnphases;  //nphases
    Q_ref1 := Q_ref;
    Q_ref2 := Q_ref;
    Q_ref3 := Q_ref;
end;

procedure TGeneric5Obj.Set_V_Ref(VrefkV: Double);
begin
    //
    V_ref := 1000 * VrefkV;
    V_ref1 := V_ref;
    V_ref2 := V_ref;
    V_ref3 := V_ref;
end;

procedure TGeneric5Obj.Update_kWbase_by_Fctrs;
begin
    kWbase := (Pmpp + Pbias) * Pfctr1 * Pfctr2 * Pfctr3 * Pfctr4 * Pfctr5 * Pfctr6;
    kWbase := kWbase / 1000;
    update_PQlimits;
end;

procedure TGeneric5Obj.update_system_abcd;
begin
    //2 order system example
    //Amn := Zeros;
    //Bmn := I;
    //Cnm := I;
   {-Done in the initial part-}
end;

procedure TGeneric5Obj.UpdateAlpha_qi;
begin
      //Update_PQlimits;
    if Qmax > epsilon then
    begin
          //pos control
        Alpha := Q_DG / Qmax;
          // phase control
        Alpha1 := Q_DG1 / Qmax_phase;

        if FNPhases = 3 then
        begin
            Alpha2 := Q_DG2 / Qmax_phase;
            Alpha3 := Q_DG3 / Qmax_phase;
        end;
    end;
end;

procedure TGeneric5Obj.Update_PQlimits;
begin
    if PQpriority = 1 then //P prior  by default
    begin
        if (Pmax <= 0) or (pmax > kWbase) then
            Pmax := kWbase * 1000;// first value is set to be kWbase;   when kWbase is set, Pmax will be update in edit;
        Pmax := kWBase * 1000;//if PQpriority=1 then
            //if (Pmax <0 )or (Pmax > kWBase*1000) then Pmax := kWBase*1000;
            //Pmax
            //Pmax; should be what it is
            //P_DG
        if 1000 * machinedata.kVArating >= P_DG then   //  Pmax P_DG
            Qmax := sqrt(machinedata.kVArating * 1000 * machinedata.kVArating * 1000 - P_DG * P_DG) // PMax*PMax)//
        else
            Qmax := epsilon;  //error when used as demoninator
        Qmin := -Qmax;
    end
    else
    if PQpriority = 0 then //Q prior
    begin
        Qmax := machinedata.kVArating;
        Qmin := -machinedata.kVArating;

        Pmax := min(sqrt(machinedata.kVArating * 1000 * machinedata.kVArating * 1000 - Q_DG * Q_DG), kWbase * 1000); //which one is smaller
        Pmin := 0;
             //Pmax_phase := Pmax / fnphases;
             //Pmin_phase := Pmin / fnphases;
    end;
        //if machinedata.kVArating <= 0 then
        //begin
        //  if fmonobj <> nil then
        //    Qmax := fmonobj.CalcAvgQmax;     //if the node is without control, Qmax := cluster avg
        //end;

    Pmax_phase := Pmax / fnphases;
    Pmin_phase := Pmin / fnphases;
    Qmax_phase := Qmax / fnphases;
    Qmin_phase := Qmin / fnphases;
      //used for limit currents derivative
    Idmax_phase := Pmax_phase / (Vbase);// vBase := kVGeneratorBase*InvSQRT31000
    Iqmax_phase := Qmax_phase / (Vbase);
end;
//----------------------------------------------------------------------------
procedure TGeneric5Obj.CalcDynamic(var V012, I012: TSymCompArray5);
//----------------------------------------------------------------------------
var
    Pref3: Double;
begin
      //Update_Pqlimits;// confirm P, Q limits
    if ctrl_mode = 0 then
    begin

        InDynamics := TRUE;
        V1 := V012[1];   // Save for variable calcs
        V2 := V012[2];

        V_DG := cabs(V1);
        Theta_DG := cang(V1);


      {P}  //P_DG follows ref, and allows sudden change

        P_DG := V_DG * Id; //update P_DG
           // if P_DG, Q_DG exceed the limits
        if P_DG > Pmax then
        begin
            P_DG := Pmax; //set real power change during the simulation
            Id := P_DG / V_DG;    //set Id
            Idn := Id;
            X_var[1] := Id;
            X_varn[1] := Idn;
            dX_vardtn[1] := 0.0;
        end
        else
        if P_DG < Pmin then
        begin
            P_DG := Pmin;
            Id := P_DG / V_DG;    //set Id
            Idn := Id;
            X_var[1] := Id;
            X_varn[1] := Idn;
            dX_vardtn[1] := 0.0;
        end;

                 {Q}
        Q_DG := V_DG * Iq;

        if Q_DG >= Qmax then
        begin
            Q_DG := Qmax;
            Iq := Q_DG / V_DG;
            Iqn := Iq;
            X_var[2] := Iq;
            X_varn[2] := Iqn;
            dX_vardtn[1] := 0.0;
        end
        else
        if Q_DG <= Qmin then
        begin
            Q_DG := Qmin;
            Iq := Q_DG / V_DG;
            Iqn := Iq;
            X_var[2] := Iq;
            X_varn[2] := Iqn;
            dX_vardtn[1] := 0.0;
        end;


        Get_DynamicModelCurrent; //Iq Iq does not change, Is1 := cmplx(Id, Iq)*1<angle Is2 := CZERO
               //Id and Iq are divided by/3.0 to be I012                     // Is2 is calculated here(In XY domain), will be used as I012
                                    // sqrt(Iq*Iq +Id*Id),Theta_DG - arctan(Iq/Id)

        AlphaP := p_DG / Pmax;
        Alpha := Q_DG / Qmax;

        I012[1] := Is1;    // Id and Iq /3.0
        I012[2] := Is2;
        I012[0] := cmplx(0.0, 0.0); //force balance
           {change direction} //added by dahei  input should be negtive
        I012[1] := cnegate(I012[1]);
        I012[2] := cnegate(I012[2]);
        I012[0] := cnegate(I012[0]);

           //CalGradient: will be published into FMonitor
    end;
end;

procedure TGeneric5Obj.CalGradient;   //failed, Q_Di and Bii are not available inside DD
                                        // will be done in FMonitor
var
    den: Double;
begin
      //Gradient :=
  // will be done in FMonitor
end;
//----------------------------------------------------------------------------
procedure TGeneric5Obj.CalcDynamicVIabc(var Vabc, Iabc: pComplexArray);
//----------------------------------------------------------------------------
//   Vabc is the terminal voltages of the connecting bus
//   Iabc will be returned as the currents injection into network
//   This func will be called after integrate, so 'Id1, Iq1,  Id2, Iq2,  Id3, Iq3' have been integrated for current time step
//   ,whcih means at the end of integration 'Id1, Iq1,  Id2, Iq2,  Id3, Iq3' shoulbe be valued
//   ' P_DG1, P_DG2,P_dg3, Q_DG1, Q_dg2,Q_dg3' will also be calculated in this func
//    'V_DG1, V_DG2,V_dg3'
var
    tempV1, tempV2, tempV3,
    Curr1,
    Curr2,
    Curr3: Complex;
    temp_pref, temp_qref, temp_vref: Double;
    tempAngleR: Double;
begin
      {----------------}
      //Update_Pqlimits;// confirm P, Q limits
      {----------------}

    if ctrl_mode = 0 then
    begin
          //will never be used
          //will be in CalcDynamic
    end // avg ctrl
    else //direct phase ctrl
    begin
        if fnphases = 3 then
        begin
               //3-phase ctrl
            InDynamics := TRUE;
            tempV1 := Vabc[1];   // Save for variable calcs
            tempV2 := Vabc[2];
            tempV3 := Vabc[3];

            V_DG1 := cabs(tempV1);
            V_DG2 := cabs(tempV2);
            V_DG3 := cabs(tempV3);
            V_Theta1 := cang(tempV1);
            V_Theta2 := cang(tempV2);
            V_Theta3 := cang(tempV3);
               ///
               ///  Model currents Iabc injectted into network by Id1, Iq1, Id2, Iq2, Id3, Iq3, Vabc/////
                //Id1, Iq1
            if Id1 = 0.0 then
                tempAngleR := pi / 2
            else
                tempAngleR := arctan(Iq1 / Id1);
            curr1 := PCLX(sqrt(Iq1 * Iq1 + Id1 * Id1), V_Theta1 - tempAngleR);//with respect to Q_axis
                //Id2, Iq2
            if Id2 = 0.0 then
                tempAngleR := pi / 2
            else
                tempAngleR := arctan(Iq2 / Id2);
            curr2 := PCLX(sqrt(Iq2 * Iq2 + Id2 * Id2), V_Theta2 - tempAngleR);//with respect to Q_axis
                //Id3, Iq3
            if Id3 = 0.0 then
                tempAngleR := pi / 2
            else
                tempAngleR := arctan(Iq3 / Id3);
            curr3 := PCLX(sqrt(Iq3 * Iq3 + Id3 * Id3), V_Theta3 - tempAngleR);//with respect to Q_axis
               //////////////////////////////////////////////////////
               ///Update power at current time step
            P_DG1 := V_DG1 * Id1;
            Q_DG1 := V_DG1 * Iq1;
            P_DG2 := V_DG2 * Id2;
            Q_DG2 := V_DG2 * Iq2;
            P_DG3 := V_DG3 * Id3;
            Q_DG3 := V_DG3 * Iq3;
                //sum
            P_DG := P_DG1 + P_DG2 + P_DG3;  //element output
            Q_DG := Q_DG1 + Q_DG2 + Q_DG3;
               ////////////////////////////////
             // inject into network
            Iabc[1] := Curr1;
            Iabc[2] := Curr2;
            Iabc[3] := Curr3;
               {change direction} //added by dahei  input should be negtive
            Iabc[1] := cnegate(Iabc[1]);
            Iabc[2] := cnegate(Iabc[2]);
            Iabc[3] := cnegate(Iabc[3]);
        end
        else
        if fnphases = 1 then
        begin
                //1-phase ctrl
            InDynamics := TRUE;
            tempV1 := Vabc[1];   // Save for variable calcs

            V_DG1 := cabs(tempV1);
            V_Theta1 := cang(tempV1);
               ///
               ///  Model currents Iabc injectted into network by Id1, Iq1, Id2, Iq2, Id3, Iq3, Vabc/////
                //Id1, Iq1
            if Id1 = 0.0 then
                tempAngleR := pi / 2
            else
                tempAngleR := arctan(Iq1 / Id1);
            curr1 := PCLX(sqrt(Iq1 * Iq1 + Id1 * Id1), V_Theta1 - tempAngleR);//with respect to Q_axis

               //////////////////////////////////////////////////////
               ///Update power at current time step
            P_DG1 := V_DG1 * Id1;
            Q_DG1 := V_DG1 * Iq1;
                //sum
            P_DG := P_DG1;//
            Q_DG := Q_DG1;
               ////////////////////////////////
             // inject into network
            Iabc[1] := Curr1;
               {change direction} //added by dahei  input should be negtive
            Iabc[1] := cnegate(Iabc[1]);
        end
        else
        begin
            //no consideration for 2-phase DG
        end;
    end;

end;

//----------------------------------------------------------------------------
procedure TGeneric5Obj.CalcPFlow(var V012, I012: TSymCompArray5);
//----------------------------------------------------------------------------

//Var P_Error:Double;
var

//   i  : Integer;
//   DQ : Double;
    Curr: Complex;
    p_mode: Integer;
begin
    if ctrl_mode = 0 then   //duplicate all codes as avg ctrl, under V120, I120
    begin
        V1 := V012[1];   // Save for variable calcs
        V2 := V012[2];
        if cabs(V1) = 0.0 then
            V1 := Cmplx(1, 0);   //in Case the first step
        InDynamics := FALSE;
             // Guess at a new var output value
        V_DG := cabs(V1);
        Theta_DG := cang(V1);
             //this should be the the online system index, has to be improved by
             //TGeneric5Obj.RememberQV
             //TGeneric5Obj.CalcDQDV
             //

             {----real power is control by Pref in DG----}
        update_pV_f_CC;  //AlphaP, Alpha
        p_mode := 0;
        if fmonobj <> NIL then
            p_mode := fmonobj.Get_P_mode;
        if (p_mode = 1) and (cc_switch = TRUE) then //if delta P = p_trans_ref - p_trans
        begin //balance p_trans
            AlphaP := pV_f_CC^[1]; //alpha_p
            p_DG := Pmax * AlphaP;
        end
        else
        begin
            P_DG := fnphases * P_ref; // local

        end;
        if (p_DG > Pmax) then
        begin
            P_DG := Pmax;
        end
        else
        if (P_DG < Pmin) then
        begin
            P_DG := Pmin;
        end;
        AlphaP := P_DG / Pmax;
             {--- real power is controled above --}
        if QV_flag = 0 then    //P_ref, Q_ref
            Curr := Conjg(Cdiv(Cmplx(P_DG / 3.0, Q_ref), V1))
        else                 //P_ref, V_ref
        begin
            if ActiveCircuit.Solution.Iteration = 1 then
            begin
                Iq := 0; //In power flow, start value of Iq for each power flow
            end;

                  //update_pV_f_CC;  //Alpha
            Alpha := pV_f_CC^[2];  // only when not dynamode
            Q_DG := Qmax * Alpha;
            Curr := Conjg(Cdiv(Cmplx(P_DG / 3.0, Q_DG / 3.0), V1));
                  {----------------}
        end;

        I012[1] := Curr;    // Save for variable calcs
        I012[2] := cmplx(0.0, 0.0);//force to be balanced output DG
        I012[0] := cmplx(0.0, 0.0);
             {change direction}//added by dahei
        I012[1] := cnegate(I012[1]);
        I012[2] := cnegate(I012[2]);
        I012[0] := cnegate(I012[0]);
    end // avg ctrl
    else //direct phase ctrl
    begin
        if fnphases = 3 then
        begin
                    //3-phase ctrl
        end
        else
        if fnphases = 1 then
        begin
                    //1-phase ctrl
        end
        else
        begin
                //no consideration for 2-phase DG
        end;
    end;
end;

procedure TGeneric5Obj.CalcPFlowVIabc(var Vabc, Iabc: pComplexArray);
//----------------------------------------------------------------------------
var
    tempV1, tempV2, tempV3,
    Curr1,
    Curr2,
    Curr3: Complex;
    temp_pref, temp_qref, temp_vref, temp_alpha: Double;
    flmt: Double;
    p_mode: Integer;
begin
    flmt := 0.9;
    Update_Pqlimits; //  Pmax_phase, Qmax_phase will be used in the following steps
    update_pV_f_CC_M2;  // pV_f_CC, updated from virtual leader
                          // Q ctrl: 3-phase,  pV_f_CC^[2], [4], [6]
                          // 1-phase,  pV_f_CC^[2]
                          // P ctrl: 3-phase,  pV_f_CC^[1], [3], [5]
                          // 1-phase,  pV_f_CC^[1]

    if fnphases = 3 then
    begin
        tempV1 := Vabc[1];  // Save for variable calcs //assume Vabc[1][2][3] is ABC!
        tempV2 := Vabc[2];
        tempV3 := Vabc[3];
        if cabs(tempV1) = 0 then
            tempV1 := Cmplx(1, 0);
        if cabs(tempV2) = 0 then
            tempV2 := Cmplx(1, 0);
        if cabs(tempV3) = 0 then
            tempV3 := Cmplx(1, 0);
    end
    else
    if fnphases = 1 then
    begin
        tempV1 := Vabc[1];  // Save for variable calcs //assume Vabc[1][2][3] is ABC!
        tempV2 := Cmplx(1, 0);
        tempV3 := Cmplx(1, 0);
    end;

    V_DG1 := cabs(tempV1);   // Save for variable calcs
    V_DG2 := cabs(tempV2);
    V_DG3 := cabs(tempV3);
      {----real power is control by Pref in DG----}
    P_DG1 := P_ref1;
    P_DG2 := P_ref2;
    P_DG3 := P_ref3;

       {}
      //calculate_gradient; //alpha, dalpha, and gradients
      //alpha is implemented in M2
    p_mode := 0;
    if fmonobj <> NIL then
        p_mode := fmonobj.Get_P_mode;
    if (p_mode = 1) and (cc_switch = TRUE) then //if delta P = p_trans_ref - p_trans
    begin
        case ctrl_mode of
            1:
            begin
                AlphaP1 := pV_f_CC^[1];
                p_DG1 := p_DG1 + Pmax_phase * AlphaP1;
                          //p_DG1 :=  Pmax_phase * AlphaP1;
            end;
            2:
            begin
                AlphaP2 := pV_f_CC^[1];//if single phase only    pV_f_CC^[1] and pV_f_CC^[2]
                p_DG2 := p_DG2 + Pmax_phase * AlphaP2;
                          //p_DG2 :=  Pmax_phase * AlphaP2;
            end;
            3:
            begin
                AlphaP3 := pV_f_CC^[1]; //if single phase only    pV_f_CC^[1] and pV_f_CC^[2]
                p_DG3 := p_DG3 + Pmax_phase * AlphaP3;
                          //p_DG3 :=  Pmax_phase * AlphaP3;
            end;
            4:
            begin
                AlphaP1 := pV_f_CC^[1];
                p_DG1 := p_DG1 + Pmax_phase * AlphaP1;
                          //p_DG1 :=  Pmax_phase * AlphaP1;
                AlphaP2 := pV_f_CC^[3];
                p_DG2 := p_DG2 + Pmax_phase * AlphaP2;
                          //p_DG2 :=  Pmax_phase * AlphaP2;
                AlphaP3 := pV_f_CC^[5];
                p_DG3 := p_DG3 + Pmax_phase * AlphaP3;
                          //p_DG3 :=  Pmax_phase * AlphaP3;
            end;
        end;
        if (p_DG1 > Pmax_phase) then
        begin
            P_DG1 := Pmax_phase;
        end
        else
        if (P_DG1 < Pmin_phase) then
        begin
            P_DG1 := Pmin_phase;
        end;
        if (P_DG2 > Pmax_phase) then
        begin
            P_DG2 := Pmax_phase;
        end
        else
        if (P_DG2 < Pmin_phase) then
        begin
            P_DG2 := Pmin_phase;
        end;
        if (P_DG3 > Pmax_phase) then
        begin
            P_DG3 := Pmax_phase;
        end
        else
        if (P_DG3 < Pmin_phase) then
        begin
            P_DG3 := Pmin_phase;
        end;
        Update_Pqlimits; //  Qmax_phase will be updated accordingly
    end;
            // calc P_DG
    case ctrl_mode of
        1:
        begin
            P_DG := P_dg1;
        end;
        2:
        begin
            P_DG := P_dg2;
        end;
        3:
        begin
            P_DG := P_dg3;
        end;
        4:
        begin
            P_DG := P_DG1 + P_DG2 + P_DG3;
        end;
    end;
      {Q Control}
    if ctrl_mode = 0 then
    begin
          //will never be used
          //will be in CalcPFlow
    end // avg ctrl
    else //direct phase ctrl
    begin
        if fnphases = 3 then
        begin
                    //3-phase ctrl
              // V_Theta1 := cang(V1);
              // V_Theta2 := cang(V2);
              // V_Theta3 := cang(V3);

            InDynamics := FALSE;

               //if (P_Mode = 1) and  then
               //real power control

               // Guess at a new var output value
            if QV_flag = 0 then    //P_ref, Q_ref
            begin
                Curr1 := Conjg(Cdiv(Cmplx(P_dg1, Q_ref1), tempV1));  //currents A,B,C
                Curr2 := Conjg(Cdiv(Cmplx(P_dg2, Q_ref2), tempV2));
                Curr3 := Conjg(Cdiv(Cmplx(P_dg3, Q_ref3), tempV3));
            end
            else                 //P_ref, V_ref
            begin
                  //phase A
                  //1 st ireration Iq := 0;
                if ActiveCircuit.Solution.Iteration = 1 then
                begin
                    Iq1 := 0; //In power flow, start value of Iq for each power flow
                    Iq2 := 0;
                    Iq3 := 0;
                end;                                                      //should be taken care of here
                if cc_switch = FALSE then    //droop                                                   //Q_DG starts from 0
                begin
                      ///////////integral droop
                    dIqdt := kcq * (V_ref1 - V_DG1) / ActiveCircuit.Solution.Iteration;
                    if abs(V_ref1 - v_DG1) <= Volt_Trhd * V_ref1 then
                        dIqdt := 0.0;

                                        //if abs(dIqdt)> flmt*Iqmax_phase then dIqdt := sign(dIqdt)*flmt*Iqmax_phase;
                    Iq1 := Iq1 + dIqdt;
                    Q_DG1 := V_DG1 * Iq1;
                    if droop = 2 then
                      /////////////////}
                        Q_DG1 := kcq_drp2 * (V_ref1 - V_DG1) * 1000 * machinedata.kVArating / 0.05 / V_ref1;
                end
                  {gradient control}
                else
                begin                       // cooperative control
                    //dIqdt := Qmax_phase/ V_DG1 * ( - kcq*Gradient1);
                    //dIqdt := dIqdt / ActiveCircuit.Solution.Iteration;
                    //dIqdt := dIqdt + Qmax_phase/ V_DG1 * (pV_f_CC[2]);//dIqdt1
                    //second method
                    //calc alpha
                    //calc Q
                    //Iq1 := Iq1 + dIqdt;
                    //Q_DG1 :=  V_DG1 * Iq1;
                    Alpha1 := pV_f_CC^[2];
                    Q_DG1 := Qmax_phase * Alpha1;
                end;
                  {----------------}
                  //if abs(dIqdt)> flmt*Iqmax_phase then dIqdt := sign(dIqdt)*flmt*Iqmax_phase;

                  //If (Q_DG1 >= Qmax_phase) then Q_DG1 := Qmax_phase; //limit check only one phase
                  //If Q_DG1 <= Qmin_phase then Q_DG1:= Qmin_phase;

                  //phase B
                if cc_switch = FALSE then    //droop
                begin
                      ///////////integral droop
                    dIqdt := kcq * (V_ref2 - V_DG2) / ActiveCircuit.Solution.Iteration;  // ref control
                    if abs(V_ref2 - v_DG2) <= Volt_Trhd * V_ref2 then
                        dIqdt := 0.0;
                    Iq2 := Iq2 + dIqdt;     //In power flow, Iq starts from 0;
                    Q_DG2 := V_DG2 * Iq2;
                    if droop = 2 then
                      /////////////////}
                        Q_DG2 := kcq_drp2 * (V_ref2 - V_DG2) * 1000 * machinedata.kVArating / 0.05 / V_ref1;
                end
                  {gradient control}
                else
                begin
                      //dIqdt := Qmax_phase/ V_DG2 * ( - kcq*gradient2); //self gradient
                      //dIqdt := dIqdt / ActiveCircuit.Solution.Iteration;
                      //dIqdt := dIqdt + Qmax_phase/ V_DG2 * (pV_f_CC[4]);//dIqdt2
                      //Iq2 := Iq2 + dIqdt;     //In power flow, Iq starts from 0;
                      //Q_DG2 :=  V_DG2 * Iq2;
                    Alpha2 := pV_f_CC^[4];
                    Q_DG2 := Qmax_phase * Alpha2;
                end;
                  //if abs(dIqdt)> flmt*Iqmax_phase then dIqdt := sign(dIqdt)*flmt*Iqmax_phase;
                  {----------------}

                  //If Q_DG2 >= Qmax_phase then Q_DG2:= Qmax_phase; //limit check only one phase
                  //If Q_DG2 <= Qmin_phase then Q_DG2:= Qmin_phase;

                  //phase C
                if cc_switch = FALSE then    //droop
                begin
                  ///////////integral droop
                    dIqdt := kcq * (V_ref3 - V_DG3) / ActiveCircuit.Solution.Iteration;
                    if abs(V_ref3 - v_DG3) <= Volt_Trhd * V_ref3 then
                        dIqdt := 0.0;
                    Iq3 := Iq3 + dIqdt;     //In power flow, Iq starts from 0;
                    Q_DG3 := V_DG3 * Iq3;
                    if droop = 2 then  /////////////////}
                        Q_DG3 := kcq_drp2 * (V_ref3 - V_DG3) * 1000 * machinedata.kVArating / 0.05 / V_ref1;
                end
                else
                begin
                   {gradient control}
                      //dIqdt := Qmax_phase/ V_DG3 * ( - kcq*gradient3);
                      //dIqdt := dIqdt / ActiveCircuit.Solution.Iteration;
                      //dIqdt := dIqdt + Qmax_phase/ V_DG3 * (pV_f_CC[6]);//dIqdt3
                      //Iq3 := Iq3 + dIqdt;     //In power flow, Iq starts from 0;
                      //Q_DG3 :=  V_DG3 * Iq3;
                    Alpha3 := pV_f_CC^[6];
                    Q_DG3 := Qmax_phase * Alpha3;
                end;

                  /// code bellow is for each phase working seperately
                if (Q_DG1 > Qmax_phase) then
                begin
                    Q_DG1 := Qmax_phase;
                end
                else
                if (Q_DG1 < Qmin_phase) then
                begin
                    Q_DG1 := Qmin_phase;
                end;
                Curr1 := Conjg(Cdiv(Cmplx(P_dg1, Q_DG1), tempV1));
                if (Q_DG2 > Qmax_phase) then
                begin
                    Q_DG2 := Qmax_phase;
                end
                else
                if (Q_DG2 < Qmin_phase) then
                begin
                    Q_DG2 := Qmin_phase;
                end;
                Curr2 := Conjg(Cdiv(Cmplx(P_dg2, Q_DG2), tempV2));
                if (Q_DG3 > Qmax_phase) then
                begin
                    Q_DG3 := Qmax_phase;
                end
                else
                if (Q_DG3 < Qmin_phase) then
                begin
                    Q_DG3 := Qmin_phase;
                end;
                Curr3 := Conjg(Cdiv(Cmplx(P_dg3, Q_DG3), tempV3));
                  /////////////////////////////////////////////////////
            end;
            Q_DG := Q_DG1 + Q_DG2 + Q_DG3;//

            Iabc[1] := Curr1;    // Save for variable calcs
            Iabc[2] := Curr2;
            Iabc[3] := Curr3;
               {change direction}//added by dahei
            Iabc[1] := cnegate(Iabc[1]);
            Iabc[2] := cnegate(Iabc[2]);
            Iabc[3] := cnegate(Iabc[3]);

        end
        else
        if fnphases = 1 then
        begin
                //1-phase ctrl

               //tempV1 := Vabc[1];  // Save for variable calcs //assume Vabc[1][2][3] is ABC!

            V_DG2 := V_DG1;   // Save for variable calcs, just in case of other use
            V_DG3 := V_DG1;
              // V_Theta1 := cang(V1);

            InDynamics := FALSE;
               // Guess at a new var output value
            case ctrl_mode of
                1:
                begin
                    temp_pref := P_dg1;//
                    temp_qref := q_ref1;
                    temp_vref := v_ref1;
                    Alpha1 := pV_f_CC^[2]; //1 phase, only first one. coincident with dynamic calc
                    temp_alpha := alpha1;
                end;
                2:
                begin
                    temp_pref := P_dg2;
                    temp_qref := q_ref2;
                    temp_vref := v_ref2;
                    Alpha2 := pV_f_CC^[2];
                    temp_alpha := alpha2;
                end;
                3:
                begin
                    temp_pref := P_dg3;
                    temp_qref := q_ref3;
                    temp_vref := v_ref3;
                    Alpha3 := pV_f_CC^[2];
                    temp_alpha := alpha3;
                end;
            end;
            if QV_flag = 0 then    //P_ref, Q_ref
            begin
                Curr1 := Conjg(Cdiv(Cmplx(temp_pref, temp_qref), tempV1));  //currents A,B,C
            end
            else                 //P_ref, V_ref
            begin    // QV_flag=1

                  //phase 1
                  //1 st ireration Iq := 0;
                if ActiveCircuit.Solution.Iteration = 1 then
                begin
                    Iq1 := 0; //In power flow, start value of Iq for each power flow
                end;
                if cc_switch = FALSE then    //droop
                begin
                    ///////////integral droop
                    dIqdt := kcq * (temp_vref - V_DG1) / ActiveCircuit.Solution.Iteration;
                    if abs(V_ref1 - v_DG1) <= Volt_Trhd * V_ref1 then
                        dIqdt := 0.0;
                    Iq1 := Iq1 + dIqdt;     //In power flow, Iq starts from 0;
                    temp_qref := V_DG1 * Iq1;
                    if droop = 2 then
                    /////////////////}
                        temp_qref := kcq_drp2 * (temp_vref - V_DG1) * 1000 * machinedata.kVArating / 0.05 / V_ref1;
                end
                else
                begin
                   {gradient control}

                    temp_qref := Qmax_phase * temp_alpha;
                end;
                  {----------------}

                if (temp_qref > Qmax_phase) then  // switch control mode to Q_ref control
                    temp_qref := Qmax_phase
                else
                if (temp_qref < Qmin_phase) then
                    temp_qref := Qmin_phase;
                Curr1 := Conjg(Cdiv(Cmplx(temp_pref, temp_qref), tempV1));
                case ctrl_mode of
                    1:
                    begin
                              //P_ref1 := temp_pref ;
                        Q_DG1 := temp_qref;
                              //v_ref1 :=  temp_vref;
                        alpha1 := temp_alpha;
                    end;
                    2:
                    begin
                              //P_ref2 :=  temp_pref;
                        Q_DG2 := temp_qref;
                              //v_ref2 := temp_vref ;
                        alpha2 := temp_alpha;
                    end;
                    3:
                    begin
                              //P_ref3 :=  temp_pref  ;
                        Q_DG3 := temp_qref;
                              //v_ref3 :=  temp_vref  ;
                        alpha3 := temp_alpha;
                    end;
                end;

         // else
         // begin
            //no consideration for 2-phase DG
            end;
            Iabc[1] := Curr1;    // Save for variable calcs
               {change direction}//added by dahei
            Iabc[1] := cnegate(Iabc[1]);
        end; //phase =1
    end; //direct phase ctrl
    //InfoPublish;    // publish data into fmonitor
end;
//*(*)//----------------------------------------------------------------------------
procedure TGeneric5Obj.Randomize(Opt: Integer);
//----------------------------------------------------------------------------

// typical proc for handling randomization in DSS fashion

begin
    case Opt of
        0:
            RandomMult := 1.0;
    //   GAUSSIAN:  RandomMult := Gauss(YearlyShapeObj.Mean, YearlyShapeObj.StdDev);
        UNIfORM:
            RandomMult := Random;  // number between 0 and 1.0
     //  LOGNORMAL: RandomMult := QuasiLognormal(YearlyShapeObj.Mean);
    end;
end;


{-------------------------------------------------------------------------------------------------------------}
procedure TGeneric5Obj.InitModel(V012, I012: TSymCompArray5);
{-------------------------------------------------------------------------------------------------------------}

// Init for Dynamics mode
begin
    if ctrl_mode = 0 then   //duplicate all codes as avg ctrl
    begin
        Id := P_DG / V_DG; //make sure V_DG has been calc beforehand
        Iq := Q_DG / V_DG;   //change P_ref/Q_ref to P_DG/Q_DG dahei 1-16-18
        Idn := Id;
        Iqn := Iq;
        Id_ref := Id;// local; may need to be changed in futher
        Iq_ref := Iq;//
         //  P_ref :=  Id_ref *v_DG;//local
         //  V_ref := v_DG;//local
           {-initiate ABCD XY-}
        X_var^[1] := Id;
        X_var^[2] := Iq;

        dIddt := 0;
        dIqdt := 0;
        dIddtn := 0;
        dIqdtn := 0;
        dvi1dt := 0;
        dvi1dtn := 0;
        dvi2dt := 0;
        dvi2dtn := 0;
           // the global part
    end;
end;

procedure TGeneric5Obj.InitModelVIabc;
{-------------------------------------------------------------------------------------------------------------}
var
    cBuffer: pComplexArray;
begin
    cBuffer := Allocmem(sizeof(cBuffer^[1]) * fnPhases);//define cBuffer
    GetPhasePower(cBuffer);

    P_DG1 := cBuffer^[1].re; //first phase or the only one
    Q_DG1 := cBuffer^[1].im;
        ///
        //InitModelVIabc(@Vabc, @Iabc); //
    Id1 := P_DG1 / V_DG1;
    Iq1 := Q_DG1 / V_DG1;
         {-initiate ABCD XY-}
    X_var^[1] := Id1;
    X_var^[2] := Iq1;
    if fnphases = 3 then //for 3 phase control the bellow is needed
    begin
        P_DG2 := cBuffer^[2].re;
        Q_DG2 := cBuffer^[2].im;
        P_DG3 := cBuffer^[3].re;
        Q_DG3 := cBuffer^[3].im;
        Id2 := P_DG2 / V_DG2; //
        Iq2 := Q_DG2 / V_DG2;
        Id3 := P_DG3 / V_DG3; //
        Iq3 := Q_DG3 / V_DG3;
        X_var^[3] := Id2;
        X_var^[4] := Iq2;
        X_var^[5] := Id3;
        X_var^[6] := Iq3;
    end;
    Reallocmem(cBuffer, 0);//free cBuffer
end;

//----------------------------------------------------------------------------
procedure TGeneric5Obj.InitStateVars;
//----------------------------------------------------------------------------

var
    i: Integer;
    V012,
    I012: TSymCompArray5;
    Vabc, Iabc: array[1..3] of Complex;
    cBuffer: pComplexArray;

begin

    YPrimInvalid := TRUE;  // Force rebuild of YPrims

    with MachineData do
    begin

           {Compute nominal Positive sequence voltage behind transient reactance}

        if MachineON then
            with ActiveCircuit.Solution do
            begin

                Yeq := Cinv(Zsp);

                ComputeIterminal;

                case Fnphases of

                    1:
                    begin
                            //E1      := Csub( CSub(NodeV^[NodeRef^[1]], NodeV^[NodeRef^[2]]) , Cmul(ITerminal^[1], Zsp));
                        for i := 1 to FNphases do
                            Vabc[i] := NodeV^[NodeRef^[i]];   // Wye Voltage
                    end;

                    3:
                    begin
                       // Calculate E1 based on Pos Seq only
                        Phase2SymComp(ITerminal, @I012);   // terminal currents

                           // Voltage behind Zsp  (transient reactance), volts

                        for i := 1 to FNphases do
                            Vabc[i] := NodeV^[NodeRef^[i]];   // Wye Voltage
                        Phase2SymComp(@Vabc, @V012);
                           //E1  := Csub( V012[1] , Cmul(I012[1], Zsp));    // Pos sequence
                    end;
                else
                    DoSimpleMsg(Format('Dynamics mode is implemented only for 1- or 3-phase Motors. IndMach012.' + name + ' has %d phases.', [Fnphases]), 5672);
                    SolutionAbort := TRUE;
                end;

                dTheta := 0.0;
                w0 := Twopi * ActiveCircuit.Solution.Frequency;
               // recalc Mmass and D in case the frequency has changed
                with MachineData do
                begin
                    Mmass := 2.0 * Hmass * kVArating * 1000.0 / (w0);   // M = W-sec
                    D := Dpu * kVArating * 1000.0 / (w0);
                end;
                Pshaft := 0 - Power[1].re;//P_DG;//Power[1].re; // Initialize Pshaft to present power consumption of motor

               //Speed := -LocalSlip * w0;    // relative to synch speed
                dSpeed := 0.0;
               {}
                if DebugTrace then     // Put in a separator record
                begin
                    Append(TraceFile);
                    Writeln(TraceFile);
                    Writeln(TraceFile, '*************** Entering Dynamics Mode ***********************');
                    Writeln(TraceFile);
                    Close(Tracefile);
                end;

            end
        else
        begin
            Theta := 0.0;
            dTheta := 0.0;
            w0 := 0;
            Speed := 0.0;
            dSpeed := 0.0;
               {}
               //Id
        end;
    end;  {With}
  ///
  ///  from here, let us deal with ctrl_mode and everything  related to control

    if ctrl_mode = 0 then   //Pos seq contrl
    begin
               {}
        V_DG := Cabs(V012[1]);// Pos Seq Control
        Theta_DG := Cang(V012[1]);
               //P_DG := 0-Power[1].re/3.0; //1-terminal, for gen has only one terminal
                                     // div 3.0 ---% 1-11-2018. each phase
        P_DG := 0 - Power[1].re;
               //Q_DG := 0-Power[1].im/3.0;
        Q_DG := 0 - Power[1].im;
               //V_ref := V_DG ; //1;//
        P_ref := P_DG / 3;
        Q_ref := Q_DG / 3;

        InitModel(V012, I012); // E2, etc , Id Iq etc
               //init alpha array
//               if fmonobj <> nil then
//                      fmonobj.Init_delay_array(ndNumincluster);
               // Shaft variables
               //Theta  := Cang(E1) ;
    end
    else
    begin   //ctrl_mode <> 0   =1,2,3,4
        //Vabc
        V_DG1 := cabs(Vabc[1]);   // Save for variable calcs
        V_DG2 := cabs(Vabc[2]);
        V_DG3 := cabs(Vabc[3]);
        cBuffer := Allocmem(sizeof(cBuffer^[1]) * fnPhases);//define cBuffer
        GetPhasePower(cBuffer);

        P_DG1 := 0.0 - cBuffer^[1].re; //first phase or the only one
        Q_DG1 := 0.0 - cBuffer^[1].im;
        ///
        //InitModelVIabc(@Vabc, @Iabc); //
        Id1 := P_DG1 / V_DG1;
        Iq1 := Q_DG1 / V_DG1;
         {-initiate ABCD XY-}
        X_var^[1] := Id1;
        X_var^[2] := Iq1;
        if fnphases = 3 then //for 3 phase control the bellow is needed
        begin
            P_DG2 := 0.0 - cBuffer^[2].re;
            Q_DG2 := 0.0 - cBuffer^[2].im;
            P_DG3 := 0.0 - cBuffer^[3].re;
            Q_DG3 := 0.0 - cBuffer^[3].im;
            Id2 := P_DG2 / V_DG2; //
            Iq2 := Q_DG2 / V_DG2;
            Id3 := P_DG3 / V_DG3; //
            Iq3 := Q_DG3 / V_DG3;
            X_var^[3] := Id2;
            X_var^[4] := Iq2;
            X_var^[5] := Id3;
            X_var^[6] := Iq3;
        end;
        Reallocmem(cBuffer, 0);//free cBuffer
    end;
  //if QV_switch = 1 then //
    // begin
          //QV_flag := QV_flag_0;
          //QV_switch := 0;// wait next limit break
    // end;
    Update_PQlimits;
end;

//----------------------------------------------------------------------------
procedure TGeneric5Obj.CalcYPrimMatrix(Ymatrix: TcMatrix);

{A typical helper function for PC elements to assist in the computation
 of Yprim
}

var
    Y, Yij, Yadder: Complex;
    i, j: Integer;
    FreqMultiplier: Double;

begin

    FYprimFreq := ActiveCircuit.Solution.Frequency;
    FreqMultiplier := FYprimFreq / BaseFrequency;  // ratio to adjust reactances for present solution frequency

    with  ActiveCircuit.solution do
        if IsDynamicModel or IsHarmonicModel then
   // for Dynamics and Harmonics modes use constant equivalent Y
        begin
            if MachineON then
                Y := Yeq   // L-N value computed in initialization routines
            else
                Y := Cmplx(EPSILON, 0.0);

            if Connection = 1 then
                Y := CDivReal(Y, 3.0); // Convert to delta impedance
            Y.im := Y.im / FreqMultiplier;  // adjust for frequency
            Yij := Cnegate(Y);
            for i := 1 to Fnphases do
            begin
                case Connection of
                    0:
                    begin
                        Ymatrix.SetElement(i, i, Y);  // sets the element
                 {
                   Ymatrix.AddElement(Fnconds, Fnconds, Y);  // sums the element
                   Ymatrix.SetElemsym(i, Fnconds, Yij);
                 }
                    end;
                    1:
                    begin   {Delta connection}
                        Yadder := CmulReal(Y, 1.000001);  // to prevent floating delta
                        Ymatrix.SetElement(i, i, Cadd(Y, Yadder));   // add a little bit to diagonal
                        Ymatrix.AddElement(i, i, Y);  // put it in again
                        for j := 1 to i - 1 do
                            Ymatrix.SetElemsym(i, j, Yij);
                    end;
                end;
            end;
        end

        else
        begin

    //  Typical code for a regular power flow  model
    //  Borrowed from Generator object

       {Yeq is typically expected as the equivalent line-neutral admittance}

            Y := Yeq;  //     Yeq is L-N quantity

       // ****** Need to modify the base admittance for real harmonics calcs
            Y.im := Y.im / FreqMultiplier;

            case Connection of

                0:
                    with YMatrix do
                    begin // WYE
                        for i := 1 to Fnphases do
                        begin
                            SetElement(i, i, Y);
                     {
                     AddElement(Fnconds, Fnconds, Y);
                     SetElemsym(i, Fnconds, Yij);
                     }
                        end;
                    end;

                1:
                    with YMatrix do
                    begin  // Delta  or L-L
                        Y := CDivReal(Y, 3.0); // Convert to delta impedance
                        Yij := Cnegate(Y);
                        for i := 1 to Fnphases do
                        begin
                            j := i + 1;
                            if j > Fnconds then
                                j := 1;  // wrap around for closed connections
                            AddElement(i, i, Y);
                            AddElement(j, j, Y);
                            AddElemSym(i, j, Yij);
                        end;
                    end;
            end;
        end;  {ELSE IF Solution.mode}

end;


//----------------------------------------------------------------------------
procedure TGeneric5Obj.CalcYPrim;
var
    i: Integer;

begin

    if YPrimInvalid then
    begin
        if YPrim_Shunt <> NIL then
            YPrim_Shunt.Free;
        YPrim_Shunt := TcMatrix.CreateMatrix(Yorder);
        if YPrim_Series <> NIL then
            Yprim_Series.Free;
        YPrim_Series := TcMatrix.CreateMatrix(Yorder);
        if YPrim <> NIL then
            YPrim.Free;
        YPrim := TcMatrix.CreateMatrix(Yorder);
    end

    else
    begin
        YPrim_Shunt.Clear;
        YPrim_Series.Clear;
        YPrim.Clear;
    end;


     // call helper routine to compute YPrim_Shunt
    CalcYPrimMatrix(YPrim_Shunt);

     // Set YPrim_Series based on a small fraction of the diagonals of YPrim_shunt
     // so that CalcVoltages doesn't fail
     // This is just one of a number of possible strategies but seems to work most of the time
    for i := 1 to Yorder do
        Yprim_Series.SetElement(i, i, CmulReal(Yprim_Shunt.Getelement(i, i), 1.0e-10));

     // copy YPrim_shunt into YPrim; That's all that is needed for most PC Elements
    YPrim.CopyFrom(YPrim_Shunt);

     // Account for Open Conductors -- done in base class
    inherited CalcYPrim;

end;

// - - - - - - - - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - - - -

//----------------------------------------------------------------------------
procedure TGeneric5Obj.DoGeneric5Model;
//----------------------------------------------------------------------------
{Compute total terminal Current }
var
    i: Integer;

begin

    CalcYPrimContribution(InjCurrent);  // Init InjCurrent Array

    CalcModel(Vterminal, Iterminal);

   //IterminalUpdated := TRUE;
    set_ITerminalUpdated(TRUE);

    for i := 1 to Nphases do
        Caccum(InjCurrent^[i], Cnegate(Iterminal^[i]));
    if (DebugTrace) then
        WriteTraceRecord;

end;

procedure TGeneric5Obj.CalcModel(V, I: pComplexArray); // given voltages returns currents

var
    V012, I012: TSymCompArray5;
begin
    if ctrl_mode = 0 then
    begin
        // Convert abc voltages to 012
        Phase2SymComp(V, @V012);

        // compute I012

        case ActiveCircuit.Solution.DynaVars.SolutionMode of
            DYNAMICMODE:
            begin
                CalcDynamic(V012, I012);
            end;
        else  {All other modes are power flow modes}
        begin
            CalcPflow(V012, I012);
        end;
        end;

        SymComp2Phase(I, @I012);       // convert back to I abc
    end // avg ctrl
    else //direct phase ctrl
    begin
        if fnphases = 3 then
        begin
                //3-phase ctrl
                        // use Vterminal Iterminal directly instead of computing 120

            case ActiveCircuit.Solution.DynaVars.SolutionMode of
                DYNAMICMODE:
                begin
                    CalcDynamicVIabc(V, I);  //if ((ctrl_mode=4)and (fnphases=3))
                end;
            else  {All other modes are power flow modes}
            begin
                CalcPflowVIabc(V, I);  // //if ((ctrl_mode=4)and (fnphases=3))
            end;
            end;
        end
        else
        if fnphases = 1 then
        begin
                //1-phase ctrl
                          // use Vterminal Iterminal directly instead of computing 120
                          // actually there is no 120 for single phase

            case ActiveCircuit.Solution.DynaVars.SolutionMode of
                DYNAMICMODE:
                begin
                    CalcDynamicVIabc(V, I);  //if (fnphases=1)
                end;
            else  {All other modes are power flow modes}
            begin
                CalcPflowVIabc(V, I);  // //if (fnphases=1)
            end;
            end;
        end
        else
        begin
            //no consideration for 2-phase DG
        end;
    end;
    {--------pullish info--------}
    if ActiveCircuit.Solution.DynaVars.SolutionMode = DYNAMICMODE then
    begin
                 //dynamode
         //if ActiveCircuit.Issolved = true then
        if fmonobj <> NIL then
            infoPublish;
    end
    else         //power flow
    begin
        if fmonobj <> NIL then
            infoPublish;
    end;

    {----------------------------}
end;

//----------------------------------------------------------------------------
procedure TGeneric5Obj.DoDynamicMode;
//----------------------------------------------------------------------------

{ This is an example taken from Generator illustrating how a PC element might
  handle Dynamics mode with a Thevenin equivalent

  Also illustrates the computation of symmetrical component values
}

{Compute Total Current and add into InjTemp}

var
    i: Integer;

begin

   // Start off by getting the current in the admittance branch of the model
    CalcYPrimContribution(InjCurrent);  // Init InjCurrent Array

   {Inj = -Itotal (in) - Yprim*Vtemp}

    CalcModel(Vterminal, Iterminal);

   //IterminalUpdated := TRUE;
    set_ITerminalUpdated(TRUE);
    for i := 1 to Nphases do
        Caccum(InjCurrent^[i], Cnegate(ITerminal^[i]));

end;

// - - - - - - - - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - - - -
{Do not support Harmonic for now}
procedure TGeneric5Obj.DoHarmonicMode;

{
  Example taken from Generator illustrating how a PC element might handle
  current calcs for Harmonics mode

  Note: Generator objects assume a Thevenin model (voltage behind and impedance)
        while Load objects assume the Spectrum applies to a Norton model injection current
}

{Compute Injection Current Only when in harmonics mode}

{Assumes spectrum is a voltage source behind subtransient reactance and YPrim has been built}
{Vd is the fundamental frequency voltage behind Xd" for phase 1}

var
    i: Integer;
    E: Complex;
    GenHarmonic: Double;

begin

   // Set the VTerminal array
    ComputeVterminal;

    with ActiveCircuit.Solution do
    begin
        GenHarmonic := Frequency / BaseFrequency; // harmonic based on the fundamental for this object
        // get the spectrum multiplier and multiply by the V thev (or Norton current for load objects)
      // ???  E := CmulReal(SpectrumObj.GetMult(GenHarmonic), VThevHarm); // Get base harmonic magnitude
      // ???  RotatePhasorRad(E, GenHarmonic, ThetaHarm);  // Time shift by fundamental frequency phase shift

        // Put the values in a temp complex buffer
        for i := 1 to Fnphases do
        begin
            cBuffer[i] := E;
            if i < Fnphases then
                RotatePhasorDeg(E, GenHarmonic, -120.0);  // Assume 3-phase IndMach012
        end;
    end;

   {Handle Wye Connection}
    if Connection = 0 then
        cbuffer[Fnconds] := Vterminal^[Fnconds];  // assume no neutral injection voltage

   // In this case the injection currents are simply Yprim(frequency) times the voltage buffer
   // Refer to Load.Pas for load-type objects
   {Inj currents = Yprim (E) }
    YPrim.MVMult(InjCurrent, @cBuffer);

end;


// - - - - - - - - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - - - -
procedure TGeneric5Obj.CalcGeneric5ModelContribution;

// Main dispatcher for computing PC Element currnts

// Calculates IndMach012 current and adds it properly into the injcurrent array
// routines may also compute ITerminal  (ITerminalUpdated flag)

begin
  //IterminalUpdated := FALSE;
    set_ITerminalUpdated(FALSE);
    with  ActiveCircuit, ActiveCircuit.Solution do
    begin
        if IsDynamicModel then
            DoDynamicMode
        else
        if IsHarmonicModel and (Frequency <> Fundamental) then
            DoHarmonicMode
        else
            DoGeneric5Model;

    end; {WITH}

   {When this is done, ITerminal is up to date}

end;

// - - - - - - - - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - - - -
procedure TGeneric5Obj.CalcInjCurrentArray;
//----------------------------------------------------------------------------

// Main procedure for controlling computation of InjCurrent array

// InjCurrent is difference between currents in YPrim and total terminal current


begin

// You usually will want some logic like this

       // If the element is open, just zero the array and return
    if Generic5SwitchOpen then
        ZeroInjCurrent

       // otherwise, go to a routine that manages the calculation
    else
        CalcGeneric5ModelContribution;

end;

// - - - - - - - - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - - - -
procedure TGeneric5Obj.GetTerminalCurrents(Curr: pComplexArray);
//----------------------------------------------------------------------------

// This function controls the calculation of the total terminal currents

// Note that it only does something if the solution count has changed.
// Otherwise, Iterminal array already contains the currents


begin

    with ActiveCircuit.Solution do
    begin
        if IterminalSolutionCount <> ActiveCircuit.Solution.SolutionCount then
        begin     // recalc the contribution
          // You will likely want some logic like this
            if not Generic5SwitchOpen then
                CalcGeneric5ModelContribution;  // Adds totals in Iterminal as a side effect
        end;
        inherited GetTerminalCurrents(Curr); // add in inherited contribution
    end;

end;

// - - - - - - - - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - - - -
function TGeneric5Obj.InjCurrents: Integer;
//----------------------------------------------------------------------------

// Required function for managing computing of InjCurrents

begin

    with ActiveCircuit.Solution do
    begin

      // Generators and Loads use logic like this:
        if LoadsNeedUpdating then
            SetNominalPower; // Set the nominal kW, etc for the type of solution being done

       // call the main function for doing calculation
        CalcInjCurrentArray;          // Difference between currents in YPrim and total terminal current

      // If (DebugTrace) Then WriteTraceRecord;

       // Add into System Injection Current Array
        Result := inherited InjCurrents;

    end;

end;

//----------------------------------------------------------------------------
procedure TGeneric5Obj.SetNominalPower;
//----------------------------------------------------------------------------
// Set shaft power
var
    Factor: Double;
    MachineOn_Saved: Boolean;

begin
    MachineOn_Saved := MachineON;
    ShapeFactor := CDOUBLEONE;
    // Check to make sure the generation is ON
    with ActiveCircuit, ActiveCircuit.Solution do
    begin
        if not (IsDynamicModel or IsHarmonicModel) then     // Leave machine in whatever state it was prior to entering Dynamic mode
        begin
            MachineON := TRUE;   // Init to on then check if it should be off
        end;


        if not MachineON then
        begin
         // If Machine is OFF enter as tiny resistive load (.0001 pu) so we don't get divide by zero in matrix
            MachineData.Pnominalperphase := -0.1 * kWBase / Fnphases;
          // Pnominalperphase   := 0.0;
            MachineData.Qnominalperphase := 0.0;   // This really doesn't matter
        end
        else
        begin    // Generator is on, compute it's nominal watts and vars
            with Solution do

                case Mode of
                    SNAPSHOT:
                        Factor := 1.0;
                    DAILYMODE:
                    begin
                        Factor := 1.0;
                        CalcDailyMult(DynaVars.dblHour) // Daily dispatch curve
                    end;
                    YEARLYMODE:
                    begin
                        Factor := 1.0;
                        CalcYearlyMult(DynaVars.dblHour);
                    end;
                    DUTYCYCLE:
                    begin
                        Factor := 1.0;
                        CalcDutyMult(DynaVars.dblHour);
                    end;
                    GENERALTIME,   // General sequential time simulation
                    DYNAMICMODE:
                    begin
                        Factor := 1.0;
                                   // This mode allows use of one class of load shape
                        case ActiveCircuit.ActiveLoadShapeClass of
                            USEDAILY:
                                CalcDailyMult(DynaVars.dblHour);
                            USEYEARLY:
                                CalcYearlyMult(DynaVars.dblHour);
                            USEDUTY:
                                CalcDutyMult(DynaVars.dblHour);
                        else
                            ShapeFactor := CDOUBLEONE     // default to 1 + j1 if not known
                        end;
                    end;
                    MONTECARLO1,
                    MONTEFAULT,
                    FAULTSTUDY:
                        Factor := 1.0;
                    MONTECARLO2,
                    MONTECARLO3,
                    LOADDURATION1,
                    LOADDURATION2:
                    begin
                        Factor := 1.0;
                        CalcDailyMult(DynaVars.dblHour);
                    end;
                    PEAKDAY:
                    begin
                        Factor := 1.0;
                        CalcDailyMult(DynaVars.dblHour);
                    end;
                    AUTOADDFLAG:
                        Factor := 1.0;
                else
                    Factor := 1.0
                end;

            if not (IsDynamicModel or IsHarmonicModel) then         //******
            begin
                if ShapeIsActual then
                    MachineData.Pnominalperphase := 1000.0 * ShapeFactor.re / Fnphases
                else
                    MachineData.Pnominalperphase := 1000.0 * kWBase * Factor * ShapeFactor.re / Fnphases;

                // cannot dispatch vars in induction machine
                // you get what you get

            end;
        end; {ELSE GenON}

    end;  {With ActiveCircuit}

   // If machine state changes, force re-calc of Y matrix
    if MachineON <> MachineOn_Saved then
        YPrimInvalid := TRUE;

end;

// - - - - - - - - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - - - -
procedure TGeneric5Obj.CalcDailyMult(Hr: Double);
//----------------------------------------------------------------------------

begin
    if (DailyDispShapeObj <> NIL) then
    begin
        ShapeFactor := DailyDispShapeObj.GetMult(Hr);
        ShapeIsActual := DailyDispShapeObj.UseActual;
    end
    else
        ShapeFactor := CDOUBLEONE;  // Default to no daily variation
end;

//----------------------------------------------------------------------------
procedure TGeneric5Obj.CalcDutyMult(Hr: Double);
//----------------------------------------------------------------------------

begin
    if DutyShapeObj <> NIL then
    begin
        ShapeFactor := DutyShapeObj.GetMult(Hr);
        ShapeIsActual := DutyShapeObj.UseActual;
    end
    else
        CalcDailyMult(Hr);  // Default to Daily Mult if no duty curve specified
end;

//----------------------------------------------------------------------------
procedure TGeneric5Obj.CalcYearlyMult(Hr: Double);
//----------------------------------------------------------------------------

begin
{Yearly curve is assumed to be hourly only}
    if YearlyShapeObj <> NIL then
    begin
        ShapeFactor := YearlyShapeObj.GetMult(Hr);
        ShapeIsActual := YearlyShapeObj.UseActual;
    end
    else
        ShapeFactor := CDOUBLEONE;  // Defaults to no variation

end;

// - - - - - - - - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - - - -
procedure TGeneric5Obj.GetInjCurrents(Curr: pComplexArray);
//----------------------------------------------------------------------------

// Gets the currents for the last solution performed

// Do not call anything that may change the basic element values from the last solution

var
    i: Integer;

begin

    CalcInjCurrentArray;  // Difference between currents in YPrim and total current

    try    // an exception here generally means an array boundary overrun
   // Copy into buffer array
        for i := 1 to Yorder do
            Curr^[i] := InjCurrent^[i];

    except
        ON E: Exception do
            DoErrorMsg('IndMach012 Object: "' + Name + '" in GetInjCurrents function.',
                E.Message,
                'Current buffer not big enough.', 568);
    end;

end;
//= = =  = = = = = = = = = = = = = = = = = = = = = = = = = = = =

// - - - - - - - - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - - - -
procedure TGeneric5Obj.DumpProperties(var F: TextFile; Complete: Boolean);
//----------------------------------------------------------------------------
{
 This procedure is require to respond to various commands such as Dump that
 write all the device's property values to a file.
}

var
    i, idx: Integer;

begin
    inherited DumpProperties(F, Complete);

    {Write out any specials here, usually preceded by a "!"}

    with ParentClass do
        for i := 1 to NumProperties do
        begin
            idx := PropertyIdxMap[i]; // Map to get proper index into property value array
            case idx of
          {Trap any specials here, such as values that are array properties, for example}
                34, 36:
                    Writeln(F, '~ ', PropertyName^[i], '=(', PropertyValue[idx], ')')
            else
                Writeln(F, '~ ', PropertyName^[i], '=', PropertyValue[idx]);
            end;
        end;

    Writeln(F);

end;


//----------------------------------------------------------------------------
procedure TGeneric5Obj.InitHarmonics;
//----------------------------------------------------------------------------

{Procedure to initialize for Harmonics solution}

{This example is extracted from Generator and constructs a Thevinen equivalent.
 Refer to Load for how to do a Norton equivalent
 }

//Var
//  E, Va:complex;
begin

    YPrimInvalid := TRUE;  // Force rebuild of YPrims

(****
     GenFundamental := ActiveCircuit.Solution.Frequency ;  // Whatever the frequency is when we enter here.

     With GenVars Do Begin

         // Xd" is used for harmonics analysis for generators
         Yeq := Cinv(Cmplx(0.0, Xdpp));      // used for current calcs  Always L-N

         {Compute reference Thevinen voltage from phase 1 current}

         IF GenON Then
           Begin

             ComputeIterminal;  // Get present value of current

             With ActiveCircuit.solution Do
             Case Connection of
               0: Begin {wye - neutral is explicit}
                    Va := Csub(NodeV^[NodeRef^[1]], NodeV^[NodeRef^[Fnconds]]);
                  End;
               1: Begin  {delta -- assume neutral is at zero}
                    Va := NodeV^[NodeRef^[1]];
                  End;
             End;

             E         := Csub(Va, Cmul(Iterminal^[1], cmplx(0.0, Xdpp)));
             Vthevharm := Cabs(E);   // establish base mag and angle
             ThetaHarm := Cang(E);
           End
         ELSE  Begin
           // If Generator is off, just set to zero
             Vthevharm := 0.0;
             ThetaHarm := 0.0;
         End;
     End;
 ***)
end;

// ******************* PROPERTY VALUES   *******************

//----------------------------------------------------------------------------
procedure TGeneric5Obj.InitPropertyValues(ArrayOffset: Integer);
//----------------------------------------------------------------------------

// required procedure to initialize the string value of the properties

begin
   // Some examples
    PropertyValue[1] := '3';        //'phases';
    PropertyValue[2] := Getbus(1);  //'bus1';
    PropertyValue[3] := '12.47';
    PropertyValue[4] := '100';
    PropertyValue[5] := '.80';
    PropertyValue[6] := 'Delta';
    PropertyValue[7] := Format('%-g', [MachineData.kVARating]);
    PropertyValue[8] := Format('%-g', [MachineData.Hmass]);
    PropertyValue[9] := Format('%-g', [MachineData.D]);
    PropertyValue[10] := '0.0053';
    PropertyValue[11] := '0.106';
    PropertyValue[12] := '0.007';
    PropertyValue[13] := '0.12';
    PropertyValue[14] := '4.0';

    PropertyValue[15] := '0.007';
    PropertyValue[16] := '0.1';
    PropertyValue[17] := 'variable';

    PropertyValue[18] := '';
    PropertyValue[19] := '';
    PropertyValue[20] := '';     {...}
    PropertyValue[21] := 'NO';
    PropertyValue[24] := '1';//GrpNum
    PropertyValue[25] := '1';//V_ref
    PropertyValue[26] := '0';//control mode

{Call inherited function to init inherited property values}
    inherited  InitPropertyValues(NumPropsThisClass);

end;


//----------------------------------------------------------------------------
function TGeneric5Obj.GetPropertyValue(Index: Integer): String;
//----------------------------------------------------------------------------

// Return i-th property value as a string

begin

    Result := '';   // Init the string
    case Index of
         // Put special cases here
         // often a good idea to convert numeric values to strings, for example
        4:
            Result := Format('%.6g', [kWBase]);
        5:
            Result := Format('%.6g', [PowerFactor(Power[1])]);
        7:
            Result := Format('%.6g', [MachineData.kVArating]);
        8:
            Result := Format('%.6g', [MachineData.Hmass]);
        9:
            Result := Format('%.6g', [MachineData.D]);
         //15:  Result := Format('%.6g', [localslip]);
        18:
            Result := YearlyShape;
        19:
            Result := DailyDispShape;
        20:
            Result := DutyShape;
         {}
        24:
            Result := Format('%d', [Cluster_Num]);
         {...}
    else

         // The default is to just return the current string value of the property
        Result := inherited GetPropertyValue(index);

    end;
end;

// ******************* END PROPERTY VALUES   *******************


//----------------------------------------------------------------------------
procedure TGeneric5Obj.IntegrateStates;
//----------------------------------------------------------------------------

{
  This is a virtual function. You do not need to write this routine
  if you are not integrating state variables in dynamics mode.
}

// Integrate state variables for Dynamics analysis
// Example from Generator

// Illustrates use of debug tracing

// Present technique is a predictor-corrector trapezoidal rule

var
    TracePower: Complex;


begin
   // Compute Derivatives and then integrate

    ComputeIterminal;

    with ActiveCircuit.Solution, MachineData do
    begin

        with DynaVars do
            if (IterationFlag = 0) then
            begin {First iteration of new time step}
          //ThetaHistory := Theta + 0.5*h*dTheta;
          //SpeedHistory := Speed + 0.5*h*dSpeed;
            end;

      // Compute shaft dynamics
        TracePower := TerminalPowerIn(Vterminal, Iterminal, FnPhases); // in watts
      //dSpeed := (TracePower.re - Pshaft - abs(D*Speed)) / Mmass;
      //dTheta  := Speed ;
        Pshaft := P_DG;  // P_DG is calculated in CalcDynamic or CalcDynamicVIabc
                       //
     // Trapezoidal method
        with DynaVars do
        begin
       //Speed := SpeedHistory + 0.5*h*dSpeed;
       //Theta := ThetaHistory + 0.5*h*dTheta;
        end;

        if DebugTrace then
            WriteTraceRecord;

        IntegrateABCD;
      //Integrate;
    end;
end;

//----------------------------------------------------------------------------
procedure TGeneric5Obj.Get_DynamicModelCurrent;
//----------------------------------------------------------------------------
var
    temp: Double;
begin
    if Id = 0.0 then
        temp := pi / 2
    else
        temp := arctan(Iq / Id);
    Is1 := PCLX(sqrt(Iq * Iq + Id * Id), Theta_DG - temp);//with respect to Q_axis
    //Is1 := cmul(Is1,cmplex());// Put this into XY domine
    Is1 := Cdivreal(Is1, 3.0);     //here we need to divide all values back to Network
    //Is1 := Cdiv(Csub(V1, E1),Zsp); // I = (V-E')/Z'
    //Is2 := Cdiv(Csub(V2, E2),Zsp); // I = (V-E')/Z'
    Is2 := cmplx(0, 0); //force balance
    // rotor current  Ir1= Is1-Vm/jXm
    Ir1 := Is1;
    //Ir1 := Csub(Is1 ,Cdiv( Csub(V1, cmul(Is1, Zsp)), Zm ));
    //Ir2 := Csub(Is2 ,Cdiv( Csub(V2, cmul(Is2, Zsp)), Zm ));
    Ir2 := cmplx(0, 0);
end;


//----------------------------------------------------------------------------
// ********************** VARIABLES ***************************************
//----------------------------------------------------------------------------

//----------------------------------------------------------------------------
function TGeneric5Obj.NumVariables: Integer;
//----------------------------------------------------------------------------
{
  Return the number of state variables

  This is a virtual function. You do not need to write this routine
  if you are not defining state variables.
  Note: it is not necessary to define any state variables
}

begin
    Result := NumGeneric5Variables;
end;


//----------------------------------------------------------------------------
function TGeneric5Obj.VariableName(i: Integer): String;
//----------------------------------------------------------------------------

{
  Returns the i-th state variable in a string

  This is a virtual function. You do not need to write this routine
  if you are not defining state variables.
}

begin
    if i < 1 then
        Exit;  // This means Someone goofed
    case i of
        1:
            Result := 'V_DG';//pos seq value
        2:
            Result := 'P_DG';
        3:
            Result := 'Q_DG';
        4:
            Result := 'V_DG1';//Phase A or the first phase if there are less than 3
        5:
            Result := 'P_DG1';
        6:
            Result := 'Q_DG1';
        7:
            Result := 'V_DG2';//Phase B if exists
        8:
            Result := 'P_DG2';
        9:
            Result := 'Q_DG2';
        10:
            Result := 'V_DG3';//phase C if exists
        11:
            Result := 'P_DG3';
        12:
            Result := 'Q_DG3';
        13:
            Result := 'Qmax';
        14:
            Result := 'Qmax_Phase';
        15:
            Result := 'Pmax';
        16:
            Result := 'Pmax_Phase';
        17:
            Result := 'Alpha';
        18:
            Result := 'Alpha1';
        19:
            Result := 'Alpha2';
        20:
            Result := 'Alpha3';
        21:
            Result := 'AlphaP';
        22:
            Result := 'AlphaP1';
        23:
            Result := 'AlphaP2';
        24:
            Result := 'AlphaP3';
        25:
            Result := 'V_ref'; //Voltage object
        26:
            Result := 'kVA'; //kVArating
        27:
            Result := 'kW'; //kVArating
        28:
            Result := 'cluster_num';
        29:
            Result := 'NdNumInCluster';
        30:
            Result := 'ctrl_mode';
        31:
            Result := 'Gradient';
        32:
            Result := 'Id';
        33:
            Result := 'Iq';
        34:
            Result := 'P_set';
        35:
            Result := 'Frequency';
        36:
            Result := 'Defense';
    else
    end;

end;

//----------------------------------------------------------------------------
function TGeneric5Obj.Get_Variable(i: Integer): Double;
//----------------------------------------------------------------------------
begin

    Result := -9999.99;   // Error Value

    //With MachineData Do
    case i of
        1:
            Result := V_DG;
        2:
            Result := P_DG / 1000;//kW
        3:
            Result := Q_DG / 1000;
        4:
            Result := V_DG1;//Phase A or the first phase if there are less than 3 phases
        5:
            Result := P_DG1 / 1000;
        6:
            Result := Q_DG1 / 1000;
        7:
            Result := V_DG2;//Phase B if exists
        8:
            Result := P_DG2 / 1000;
        9:
            Result := Q_DG2 / 1000;
        10:
            Result := V_DG3;//Phase c if exists
        11:
            Result := P_DG3 / 1000;
        12:
            Result := Q_DG3 / 1000;
        13:
            Result := Qmax / 1000;
        14:
            Result := Qmax_Phase / 1000;
        15:
            Result := Pmax / 1000;
        16:
            Result := Pmax_Phase / 1000;
        17:
            Result := alpha;
        18:
            Result := Alpha1;
        19:
            Result := Alpha2;
        20:
            Result := Alpha3;
        21:
            Result := alphaP;
        22:
            Result := AlphaP1;
        23:
            Result := AlphaP2;
        24:
            Result := AlphaP3;
        25:
            Result := V_ref;
        26:
            Result := MachineData.kVArating / 1000;
        27:
            Result := kWbase / 1000;
        28:
            Result := cluster_num;
        29:
            Result := NdNumInCluster;
        30:
            Result := ctrl_mode;
        31:
            Result := Gradient;
        32:
            Result := Id;
        33:
            Result := Iq;
        34:
            Result := P_ref * 3.0;
        35:
        begin
            freq := ActiveCircuit.solution.Frequency;
            if fmonobj <> NIL then
                freq := freq + fmonobj.omg_fm;//fmonobj.comp_omg;//fmonobj.omg_fm;  //
            Result := freq;
        end;
        36:
        begin
            result := 0.0;
            if fmonobj <> NIL then
                Result := z_dfs_plot;
        end;
    else

    end;

end;

//----------------------------------------------------------------------------
procedure TGeneric5Obj.Set_Variable(i: Integer; Value: Double);
//----------------------------------------------------------------------------

begin
    case i of
        1:
            V_DG := Value;
        2:
            P_DG := Value;
        3:
            Q_DG := Value;
        4:
            V_DG1 := Value;//Phase A or the first phase if there are less than 3 phases
        5:
            P_DG1 := Value;
        6:
            Q_DG1 := Value;
        7:
            V_DG2 := Value;//Phase B if exists
        8:
            P_DG2 := Value;
        9:
            Q_DG2 := Value;
        10:
            V_DG3 := Value;//Phase c if exists
        11:
            P_DG3 := Value;
        12:
            Q_DG3 := Value;
        13:
            Qmax := Value;
        14:
            Qmax_Phase := Value;
        15:
            Pmax := Value;
        16:
            Pmax_Phase := Value;
        17:
            alpha := Value;
        18:
            Alpha1 := Value;
        19:
            Alpha2 := Value;
        20:
            Alpha3 := Value;
        21:
            alphaP := Value;
        22:
            alphaP1 := Value;
        23:
            alphaP2 := Value;
        24:
            alphaP3 := Value;
        25:
            V_ref := Value;
        26:
            MachineData.kVArating := Value;
        27:
            kWbase := Value;
        28:
        begin

            TPCElement(self).cluster_num := trunc(Value);


          //if cluster_num >= 1 then      // assign the virtue leader to this DG
          //begin
              //FMonObj := ActiveCircuit.Fmonitors.Get(cluster_num); // it works only if cluster_num starts from 1 and being consecutively

              // move this piece of codes to Fmonitor, InitFM
              //ActiveCircuit.Fmonitors.First;
              //FMonObj := ActiveCircuit.Fmonitors.Active;
              //if FMonObj. then


          //end;

     //if function 'get' fails , return nil
        end;
        29:
            TPCElement(self).NdNumInCluster := trunc(Value);
        30:
            TPCElement(self).nVLeaders := trunc(Value);
        31:
            TPCElement(self).cluster_num2 := trunc(Value);
        32:
            TPCElement(self).NdNumInCluster2 := trunc(Value);
    else
        {Do Nothing for other variables: they are read only}
    end;
end;

//----------------------------------------------------------------------------
procedure TGeneric5Obj.GetAllVariables(States: pDoubleArray);
//----------------------------------------------------------------------------
{
  Return all state variables in double array (allocated by calling function)

  This is a virtual function. You do not need to write this routine
  if you are not defining state variables.
}
var
    i: Integer;
    //N:Integer;
begin
//     N := 0;
    for i := 1 to NumGeneric5Variables do
        States^[i] := Variable[i];
end;

// ********************** END VARIABLES ***************************************


//----------------------------------------------------------------------------
function TGeneric5Obj.GetRotorLosses: Double;
//----------------------------------------------------------------------------
begin
    Result := 3.0 * (Sqr(Ir1.re) + Sqr(Ir1.im) + Sqr(Ir2.re) + Sqr(Ir2.im)) * Zr.re;
end;

//----------------------------------------------------------------------------
function TGeneric5Obj.GetStatorLosses: Double;
//----------------------------------------------------------------------------
begin
    Result := 3.0 * (Sqr(Is1.re) + Sqr(Is1.im) + Sqr(Is2.re) + Sqr(Is2.im)) * Zs.re;
end;


//----------------------------------------------------------------------------
procedure TGeneric5Obj.MakePosSequence;
//----------------------------------------------------------------------------

{
  This is a virtual function. You do not need to write this routine
  if the base class function will suffice.
}

// Routine to convert existing three-phase models to a single-phase positive-
// sequence model

var
    S: String;
//    V :Double;

begin

{
     The usual technique is to create a new property editing string
     based on the present values of properties. Once the string is
     created, it is pushed into the Parser and the Edit routine for this
     class is invoked.

     Thus, the positive sequence model is created in memory. Do a
     "Save Circuit" command to save the model that is created. Some
     editing of the resulting scripts will likely be required. Not all
     elements have an obvious positive sequence equivalent.
}


 // example from Generator class
 // Modify as necessary

    S := 'Phases=1 conn=wye';    // Positive sequence model is 1-phase wye

  (****

  // Make sure voltage is line-neutral
  If (Fnphases>1) or (connection<>0) Then   V :=  GenVars.kVGeneratorBase/SQRT3
  Else V :=  GenVars.kVGeneratorBase;

  S := S + Format(' kV=%-.5g',[V]);

  // Divide the load by no. phases
  If Fnphases>1 Then
  Begin
      S := S + Format(' kW=%-.5g  PF=%-.5g',[kWbase/Fnphases, PFNominal]);
      If (PrpSequence^[19]<>0) or (PrpSequence^[20]<>0) Then S := S + Format(' maxkvar=%-.5g  minkvar=%-.5g',[kvarmax/Fnphases, kvarmin/Fnphases]);
      If PrpSequence^[26]>0 Then S := S + Format(' kva=%-.5g  ',[genvars.kvarating/Fnphases]);
      If PrpSequence^[27]>0 Then S := S + Format(' MVA=%-.5g  ',[genvars.kvarating/1000.0/Fnphases]);
  End;

  Parser.CmdString := S;   // Push the string into the Parser object
  Edit;    // Invoke the Edit method for this class

  inherited;  // sets the terminal bus references, must do after editing number of phases

  ***)

end;

//----------------------------------------------------------------------------
procedure TGeneric5Obj.Set_ConductorClosed(Index: Integer; Value: Boolean);
//----------------------------------------------------------------------------

// Routine for handling Open/Close procedures

begin
    inherited;

    if Value then
        Generic5SwitchOpen := FALSE
    else
        Generic5SwitchOpen := TRUE;

end;


//----------------------------------------------------------------------------
{procedure TGeneric5Obj.set_Localslip(const Value: Double);
//----------------------------------------------------------------------------

  Function Sign(const x:Double):Double;
  Begin If x<0.0 then Result := -1.0 Else Result := 1.0; End;

begin
     S1 := Value;
     If Not InDynamics Then If Abs(S1)>MaxSlip Then S1 := Sign(S1)*MaxSlip;   // Put limits on the slip  unless dynamics
     S2 := 2.0 - S1;
end;
 }
//----------------------------------------------------------------------------
{procedure TGeneric5Obj.Set_Slip(const Value: Double);
//----------------------------------------------------------------------------
begin
        LocalSlip := Value;
        MachineData.Speed := MachineData.w0 *  (-S1); // make motor speed agree
end;
}
//----------------------------------------------------------------------------
procedure TGeneric5Obj.InitTraceFile;
//----------------------------------------------------------------------------
begin

    AssignFile(TraceFile, Format('%s_IndMach012_Trace.CSV', [Name]));
    Rewrite(TraceFile);

    Write(TraceFile, 'Time, Iteration, S1, |IS1|, |IS2|, |E1|, |dE1dt|, |E2|, |dE2dt|, |V1|, |V2|, Pshaft, Pin, Speed, dSpeed');
    Writeln(TraceFile);

    CloseFile(TraceFile);
end;

//----------------------------------------------------------------------------
procedure TGeneric5Obj.WriteTraceRecord;
//----------------------------------------------------------------------------
begin
    Append(TraceFile);
    with ActiveCircuit.Solution do
      //Write(TraceFile, Format('%-.6g, %d, %-.6g, ',[Dynavars.dblHour*3600.0, Iteration, S1]));

        Write(TraceFile, Format('%-.6g, %-.6g, ', [Cabs(Is1), Cabs(Is2)]));
      //Write(TraceFile, Format('%-.6g, %-.6g, %-.6g, %-.6g, ', [Cabs(E1), Cabs(dE1dt), Cabs(E2), Cabs(dE2dt)]));
    Write(TraceFile, Format('%-.6g, %-.6g, ', [Cabs(V1), Cabs(V2)]));
    Write(TraceFile, Format('%-.6g, %-.6g, ', [MachineData.Pshaft, power[1].re]));
    Write(TraceFile, Format('%-.6g, %-.6g, ', [MachineData.speed, MachineData.dSpeed]));

    Writeln(TraceFile);

    CloseFile(TraceFile);
end;

initialization

// Initialize any variables here


  // For Example:  1 + j 1

    CDOUBLEONE := CMPLX(1.0, 1.0);


end.
