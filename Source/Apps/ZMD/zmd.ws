. MARGINS: RIGHT=65; LEFT=
.op
.he** 09/29/88 **   ZMD Reference Manual - Version 1.50      
.foCopyright (c) 1987, 1988  Robert W. Kramer III  ALL RIGHTS RESERVED
 



















            ZMD File Transfer Program for the Z80 RCP/M

                 External Reference Specification

                       ZMD - Version 1.50
.PAŠ.pn 1
.he** 09/29/88 **   ZMD Reference Manual - Version 1.50         Page #

     CONTENTS

     1.°       Introductioî tï ZMD..........................® 4

     2.°       Applicablå Files.............................® 5

     3.°       Installation.................................® 8

       3.±     Locaì CRÔ Cleaò Screeî Sequences.............. 8

       3.²     Input/Output.................................. 8
         3.2.± Modeí......................................... 8
         3.2.² Microprocessoò Speed.......................... 9
         3.2.³ Modeí Speeä Indicatoò Byte.................... 9
         3.2.´ Disë Writå Locë Flag.......................... 9
         3.2.µ Sleepù Calleò Timeout......................... 9
         3.2.¶ Minimuí Speeä foò 1ë Blocks................... 9
         3.2.· File Transfer Buffer Queue.................... 10
         3.2.¸ Pagå Pausing.................................. 10
         3.2.9 Automatic Calculation of Disk Buffer Size..... 10

       3.³     Timekeeping................................... 11
         3.3.± MBYE/BYEµ Clocë Support....................... 11
         3.3.² ZMÄ Internaì Clock/Datå Readeò Code........... 11
         3.3.³ Restrictinç Downloadó tï Timå Left............ 12
         3.3.´ Maximuí Timå Allowed.......................... 12
         3.3.µ Displaù Timå oî Systeí messages............... 12
         3.3.6 Logon Hour/Minute Addresses................... 12

       3.´     Accesó Restrictions........................... 13
         3.4.± ZCMD/ZCPR..................................... 13
         3.4.² WHEEÌ Byte.................................... 13
         3.4.³ Maximuí Drive/User............................ 13
         3.4.´ BYE/BBÓ Prograí Accesó Flaç Byte.............. 13

       3.µ     Uploaä Configuration.........................® 14
         3.5.± Preformatteä BBÓ Messagå Uploads.............. 14
         3.5.² Hidinç Ne÷ Uploadó Untiì Approveä bù Sysop.... 14
         3.5.³ Uploaä Routinç tï Multiplå Drive/Users........ 14
         3.5.4 Uploadinç tï Specifieä Drive/User............. 14
         3.5.5 Receivinç Privatå Uploads..................... 15
         3.5.¶ Creditinç Uploaä Timå tï Timå Left............ 15
         3.5.· Receivinç .COÍ Fileó Securely................. 15

       3.¶     Uploaä Descriptions........................... 16
         3.6.± Forwardinç Descriptionó tï BBÓ Messagå Base... 16
         3.6.² Forwardinç Descriptionó tï FOÒ Texô File...... 16
         3.6.³ Desriptioî Filå Filename/Drive/User........... 16
         3.6.´ Uploaä Descriptioî Headeò Information......... 17
         3.6.µ Includinç Filå Descriptors.................... 17
         3.6.¶ Includinç Uploaä Drive/Useò Area.............. 17
         3.6.· Datestampinç thå Descriptioî Header........... 17
         3.6.¸ Overridinç Descriptioî Requests............... 17
         3.6.¹ Automatiã Worä Wrap........................... 18Š
       3.·     Downloaä Configurations....................... 19
         3.7.± Restrictinç .LBÒ anä Singlå F± Taggeä Files... 19
         3.7.² Disallo÷ Sendinç .COÍ Files................... 19
         3.7.³ Disallo÷ Sendinç .??£ Files................... 19
         3.7.´ Disallo÷ Sendinç F² Taggeä $SYSteí Files...... 20
         3.7.µ Sendinç F³ Taggeä Fileó Regardlesó oæ Access.. 20
         3.7.¶ Speciaì Sysoğ Downloadó tï Selecteä Caller.... 20

       3.¸     Logkeeping.................................... 21
         3.8.± Makinç ZMD.LOÇ File..........................® 21
         3.8.² Europeaî Datå Formaô (DD/MM/YY)............... 21
         3.8.³ Transfeò Loç Drive/User/Filename.............. 21
         3.8.´ LASTCALÒ Filå Information..................... 21
         3.8.µ Countinç Filå Transferó foò BBÓ Software...... 21

.paŠ
     APPENDICES


     APPENDIØ A.............................................. 23

       A.±     Modem Interface............................... 23
         A.1.1 Creating Modem I/O Overlays................... 23
         A.1.2 Installing Modem I/O Overlays................. 23


     APPENDIØ B.............................................. 25

       B.±     RTÃ Clock/Datå Readeò Codå.................... 25


     APPENDIØ C.............................................. 26

       C.±     Filå Descriptors/Categories................... 26


     APPENDIØ D.............................................. 27

       D.±     Uploaä Routinç Table.......................... 27
.paŠ
     1.°       Introductioî tï ZMD

     ZMÄ  ió  á  Remotå CP/Í Filå  Transfeò  Prograí  writteî  iî 
     MICROSOFÔ  MACRO-8° languagå usinç ZILOÇ Z8°  assembler®  Iô 
     wilì  ruî  oî anù Z8° microprocessoò usinç CP/Í ² oò  ³  anä 
     provideó  fulì supporô foò systemó runninç ZCMÄ oò ZCPÒ  CCĞ 
     replacement® ZMÄ caî bå configureä tï ruî undeò mosô populaò 
     remotå  consolå  programs¬  buô ió  primarilù  targeteä  foò 
     BYE5+¬  MBYÅ anä BYE3¬ oò aó aî entirelù stanä alonå prograí 
     usinç  modem/porô overlayó foò modeí I/O®   Fulì supporô  ió 
     provideä foò mosô oæ thå populaò BBÓ softwarå sucè aó  PBBS¬ 
     MBBS¬  RBBS¬ Metal¬ Oxgate¬ ZBBÓ anä others®  Communicationó 
     programó sucè aó MODEM7¬ MEX¬ MEX+¬ PROCOMM¬ ProYam¬ QMODEM¬ 
     IMĞ anä otheró arå alì alsï fullù compatible.

     Thió  manuaì  ió  noô intendeä tï bå specifiã iî  detaiì  tï 
     thå internaì characteristicó oæ ZMÄ anä utilities®   Iô  waó 
     writteî  aó á guidå tï helğ thå implementeò decidå whicè  oæ 
     thå  optionó anä featureó wilì bå useä oî hió  system®

     Aî  internaì referencå manuaì coverinç thå ZMDSUBS.REÌ  filå 
     anä  user'ó  manuaì  haó  beeî  iî  thå  making®  Additionaì 
     modem/porô overlayó wilì bå addeä tï thå ZMDOVLn.LBÒ filå aó 
     theù  arå  created®  Á ZMDCLOCK.LBÒ ió beinç considereä  foò 
     organizinç  approveä RTÃ inserts®   Therå arå  manù  planneä 
     features®   Iæ  yoõ havå anù ideaó foò changeó oò additions¬ 
     feeì freå tï contacô me.

          Robert W. Kramer III       RI RCPM-RDOS  (128mb)
          1569 40th St.              300/1200/240° - 24hrs
          Rock Island, Il  61201     Data:  (309) 786-6227
                                     Voiceº (309© 786-671±

     Features:

        ï  Menõ driveî instalì prograí with intelligence
        o  Automatic installation of new releases
        ï  User definable modeí/port I/Ï routineó
        ï  µ seconäs to gather 255 filenames in batch mode!
        o  Multiple drive/users fully supported in Batch send
        o  Overlayable .COM file installation
        o  Upload routing to multiple drive/user areas
        o  Time and Datestamping in upload description header
        o  100% MBYE/BYE3/BYE5 compatible
        o  Truly capable of standalone operation
        o  Automatic batch enable (eliminates the 'SB' command)
        o  Automatic 'k' block detection of host
        o  Fully CP/M 2.n and CP/M 3.n compatible
        o  ARC/ARK/LBR member extraction support
        o  Automatic BYEBDOS - I/O overlay detection
        ï  Fasteò erroò checkinç resultinç iî quicker transfers
        o  No delays between files in batch transfers
.paŠ
     2.0        Applicable Files

     Filenamå     Kâ                    Purpose
     ZMDHDR .Z80          Thió  filå  containó  alì  thå  prograí 
                          switcheó  anä valueó lookeä aô  bù  alì 
                          thå ZMÄ programs®   Iô ió noô needeä iæ 
                          usinç  thå installatioî prograí ZINSTÌ.

     ZMDSUBS.REL‚          Contains the common subroutines for all 
                          ZMÄ  anä  supporô utilities®   Thió  ió 
                          useä  wheî  linkinç á  newlù  assembleä 
                          versioî oæ onå oæ thå programs®  Sourcå 
                          codå ió noô releaseä foò thió file®

     ZINSTL .COM          Thió  ió  thå instalì prograí  useä  tï 
                          configurå thå ZMD anä utilitù programs®  
                          Wheî firsô ran¬  ZINSTÌ readó thå firsô 
                          1°  recordó  oæ ZMD.COÍ oî thå  currenô 
                          drive/user®   Iæ noô found¬ promptó foò 
                          á ne÷ drive/useò tï loç intï anä  trieó 
                          again®   Á  fasô  anä easù tï uså  menõ 
                          driveî  displaù  showinç  alì   currenô 
                          prograí settings®  Afteò editinç anù oæ 
                          thå switches/values¬ á selectioî oæ 'J§ 
                          iî thå maiî menõ wilì writå thå currenô 
                          configuratioî   (firsô  11  recordó  oæ 
                          ZINSTL©  bacë  tï ZMD anä ALÌ  oæ  it'ó 
                          utilities®  Uså iô oî thå flù tï changå 
                          switcheó  anä  valueó  quicklù  withouô 
                          havinç  tï  reassemblå  anything®  Thió 
                          takeó  onlù secondó anä allowó yoõ  thå 
                          versatilitù oæ changinç addresses¬ filå 
                          descriptors/categories¬ upload/downloaä 
                          drive/useò  areas¬  timå  restrictions¬ 
                          etc®  Anythinç  founä iî thå ZMDHDR.Z8° 
                          configuratioî headeò caî bå editeä froí 
                          withiî  ZINSTL®   Sourcå  codå  ió  noô 
                          provideä foò thió program®  Iæ yoõ makå 
                          anù  modificationó  tï  thå  ZMDHDR.Z8° 
                          configuratioî  file¬   ZINSTÌ  wilì  NÏ 
                          longeò  bå  ablå tï instalì  youò  .COÍ 
                          fileó properly.

     ZMD    .COM‚          Maiî  filå   transfeò  program®   Leavå 
     ZMD    .Z80          thió onå onlinå foò publiã uså (Usuallù 
                          A0:)®  Iô provideó fulì systeí securitù 
                          whilå   presentinç   á  useò   freindlù 
                          interfacå  tï  uploadó  anä  downloads®  
                          YMODEÍ 1ë anä YMODEÍ 1ë  Batch¬  XMODEÍ 
                          12¸  bytå  CRC¬  anä  XMODEÍ  12¸  bytå 
                          checksuí  arå supporteä witè  automatiã 
                          protocoì detect.
.paŠ
     Filenamå     Kâ  CRÃ               Purpose
     ZMAP   .COM          Publiã upload/downloaä  matriø  displaù 
     ZMAP   .Z80          program®  Alsï  completelù  installablå
                          witè thå ZINSTÌ program®  Privatå areaó 
                          are shown only if WHEEL byte is on.

     ZFORS  .COM          Sysoğ  descriptioî filå utility®   Thió 
     ZFORS  .Z80          onå    allowó   thå   Sysoğ   tï    adä 
                          descriptionó  tï thå FOÒ texô filå  (oò 
                          BBÓ  messagå base)®   Thió prograí wilì 
                          noô   ruî   unlesó   descriptionó   arå 
                          enabled.

     ZNEWÓ  .COM‚          Sysoğ  filå transfeò loç utility®  Thió 
     ZNEWS  .Z80          onå  allowó  thå Sysoğ  tï  appenä  thå 
                          ZMD.LOÇ  filå witè á ne÷ uploaä  entry®  
                          Thió  procedurå  currentlù  supportó  ± 
                          entry per program run.

     ZMDEÌ  .COM‚          Sysoğ filå transfeò  loç purgå utility® 
     ZMDEL  .Z80          Cleanó  thå ZMD.LOÇ filå oæ alì entrieó 
                          excepô foò "R¢ uploadeä entries®   Thió 
                          keepó  thå  loç filå  aô  á  reasonablå 
                          size.

     ZNEWĞ  .COM‚          Publiã filå transfeò loç utilitù allowó 
     ZNEWP  .Z80          calleró  tï quicklù vie÷ statisticó  oæ 
                          recenô  uploadó sucè aó thå drive/user¬ 
                          filå sizå iî kilobytes¬  datå oæ uploaä 
                          (iæ  clock/datå optionó  arå  enabled)¬ 
                          etc®   Thió  prograí ió usuallù  placeä 
                          on A0:.

     ZFORĞ  .COM‚          Publiã uploaä  descriptioî  search  anä 
     ZFORP  .Z80          displaù  utility®  Useró  caî vie÷  thå 
                          descriptionó   onlinå  oæ   thå   fileó 
                          recentlù   uploaded®    Strinç   searcè 
                          capabilitieó  arå  supporteä  tï  allo÷ 
                          'picking§ thå descriptionó desired®   Á 
                          calleò    caî    quicklù    vie÷    alì 
                          descriptionó pertaininç tï 'IBM'¬ 'Z80§ 
                          oò anù strinç thaô wilì fiô oî thå hosô 
                          system'ó   commanä   line®     Multiplå 
                          strinç searcè ió alsï supported¬  aó ió 
                          datå  searcheó (iæ enabled©  anä  fileó 
                          locateä  iî  á specifiã drive/useò  (iæ 
                          thaô  featurå  ió  enabled)®    Á  nicå 
                          companion for ZMD.


.paŠ














     ------------------------------------------------------------
     NOTEº  Tï  prevenô possiblå discrepencieó withiî thå ZMDSUBÓ 
     subroutineó file¬  alì programó havå beeî designeä tï  aborô 
     witè  erroò iæ thå program'ó maiî featurå ió disabled®   Foò 
     example¬  ZFORÓ  wilì  noô ruî unlesó iô haó beeî  installeä 
     witè descriptionó enabled®  ZMÄ caî noô bå disabled¬ howeveò 
     wilì  aborô  witè erroò iæ thå modeí I/Ï  routineó  arå  noô 
     found®  Pleaså dï noô trù tï disable thió prograí function.
     ------------------------------------------------------------
.paŠ
     3.0        Installation

     3.1        Local CRT Clear Screen Sequences

     CLRSCRÎ  seô  tï  YEÓ enableó ZMÄ anä alì utilitù  fileó  tï 
     cleaò  youò screeî locallù durinç batcè filå  transferó  anä 
     menõ displays®  Iæ youò terminaì requireó á ^Ú (1AH)¬  leavå 
     CLRSTR‚ alone®  Otherwiså yoõ wilì havå tï includå youò cleaò 
     screeî sequencå aô labeì CLRSTR®  Uğ tï ¶ byteó arå allowed.
     This CLS sequence is terminated with a '$'.

     STOPº  Iæ runninç ZMÄ anä utilitieó aó á stanä alonå packagå 
     anä  youò  locaì  consolå outpuô vectoò  addresó  cannoô  bå 
     calculateä  usinç standarä CP/Í conventionó (i.e®  youò BIOÓ 
     JĞ  tablå haó beeî altered)¬   yoõ wilì neeä tï providå  thå 
     addresó yourselæ aô labeì CONOUÔ iî youò port/modeí overlay®  
     Thió ió cruciaì tï ZMÄ eveî wheî noô usinç thå cleaò  screeî 
     featurå  aó thå recorä counô ió displayeä locallù durinç thå 
     filå transfeò anä anù outpuô oæ thió naturå tï thå modeí  aô 
     thió timå woulä causå seriouó problems.


     3.2        Input/Output

     3.2.1      Modem

     ZMÄ provideó fulì supporô foò thå Extendeä BDOÓ calló seô uğ 
     bù  somå  Remotå Consolå Programó sucè aó BYEµ  oò  MBYE44+® 
     Iî ordeò tï uså thió method¬ simplù skiğ thå overlaù procesó 
     outlineä iî APPENDIØ A®  Iæ nï overlaù ió included¬ ZMÄ wilì 
     uså  BYE'ó modeí I/Ï routineó alreadù  established®   Iæ  aî 
     attempô  tï seô thå currenô useò areá tï 24± returnó á valuå 
     oæ  7· iî registeò A¬  thå followinç calló tï BDOÓ  musô  bå 
     handled by your BYE program:

          BDOS
          Call       Function
          ----  ---------------------
           61   Check receive ready
           62   Check send ready
           63   Send a character
           64   Receive a character
           65   Check carrier
           66   Console status
           67   Console input
           68   Local console output       

     Iæ  youò BYÅ prograí doeó noô seô uğ it'ó modeí I/Ï routineó 
     foò  publiã  accesó bù outsidå programs¬  yoõ wilì  havå  tï 
     follo÷  thå  overlaù  procedurå outlineä iî  APPENDIØ  Á  oî  
     Modem Interface‚ tï instalì youò modeí routines.

     NOTE:‚   Thió  featurå ió fullù automatic®  Nï  matteò  whicè 
     methoä  yoõ use¬   ZMÄ wilì know®Š
     3.2.2      Microprocessor Speed

     MHÚ  ió  defineä tï represenô youò  system'ó  microprocessoò 
     speed®  Thió allowó ZMD tï accuratelù timå delayó anä sleepù 
     calleò timeouts®  Musô bå integeò valuå iî thå rangå oæ 1-9.


     3.2.3      Modem Speed Indicator Byte

     MSPEEÄ  shoulä  contaiî  thå  addresó oæ  youò  modeí  speeä 
     indicatoò  byte®   Thió ió needeä sï thaô ZMÄ caî  calculatå 
     thå  amounô  oæ timå needeä foò transferó anä  foò  transfeò 
     speeä  insertioî iî thå loç filå entry®   Youò  BYÅ  prograí 
     shoulä  stufæ  thió integeò valuå somewherå  iî  memory®  Aî 
     integeò valuå oæ 1-¹ musô corresponä aó illustrated:

               Value    Bps            Value    Bps
               -----  -------          -----  -------
                 1       300             7      4800
                 5      1200             8      9600
                 6      2400             9     19200


     3.2.4      Disk Write Lock Flag
     
     WRTLOÃ  ió  thå higè memorù bytå togglå useä  foò  disablinç 
     BYE'ó  abilitù  tï hanç uğ wheî thå caller'ó timå ió  uğ  oò 
     carrieò ió lost®   Thió allowó currenô disë writå operationó 
     tï  bå completeä first®  Checë youò BBÓ documentatioî - manù 
     moderî systemó don'ô neeä this®   Iæ unsure¬ seô thió tï NO®  
     Codå  tï seô anä reseô thió togglå assumeó iô tï bå  locateä 
     LOCOFÆ byteó froí thå JĞ COLDBOOÔ vectoò aô thå beginninç oæ 
     thå BYÅ BIOÓ jumğ table®  (YEÓ foò MBBÓ anä PBBS).
     

     3.2.5      Sleepy Caller Timeout

     DESWAIÔ  ió  thå numbeò oæ minuteó oæ inactivitù  durinç  aî 
     uploaä  descriptioî oò anù prompô beforå abortinç thå  inpuô 
     routine®  (0-255¬  ° disableó thió feature)®    Iæ á timeouô 
     occuró durinç descriptioî entry¬  thå currenô disë buffeò ió 
     writteî tï disë anä thå prograí exitó tï CP/Í givinç controì 
     back to your BYE program (if WRTLOC is YES).


     3.2.6      Minimum Speed for 1k Blocks

     MINKSPD‚ ió thå minimuí modeí speeä alloweä tï transfeò fileó 
     usinç 1ë blocks®   Iæ oî á networë sucè aó PÃ  Pursuit¬  anä 
     arå ablå tï receivå incominç calls¬ seô thió bytå  tï 1® Thå 
     delayó  theså networkó uså tï senä datá bacë anä fortè  makå 
     1ë packetó advantageouó tï eveî 30° bpó users®   Iæ noô oî á 
     networë sucè aó PÃ Pursuit¬ it'ó á matteò oæ preference¬ Seå 
     illustratioî iî figurå 3.2.³ foò lisô oæ modeí speeä values.Š
     3.2.7      File Transfer Buffer Queue

     BUFSIÚ  allowó yoõ tï changå thå numbeò oæ 1ë blockó  beforå 
     writinç  buffeò tï disk®   Normaì disë systemó caî  transfeò 
     16ë  froí computeò tï disë iî 2-3-´ secondó  oò  less®  Somå 
     verù  slo÷  5-1/4¢ floppù systemó (sucè aó Nortè  Star©  maù 
     takå uğ tï 20-3° secondó tï transfeò 16k®   Thió woulä causå 
     severaì timeoutó aô 1° secondó each®   Iæ yoõ experiencå anù 
     timeouts¬ trù changinç thió tï somethinç smaller¬ perhapó 8ë 
     oò eveî 4k.
     

     3.2.8      Page Pausing

     PAGLEÎ  ió seô tï thå numbeò oæ lineó tï displaù iî  betweeî 
     [moreİ  pauseó  anä menõ displays®   (Seô tï  °  tï  disablå 
     page pauses.


     3.2.9      Automatic Calculation of Disk Buffer Size

     STDBUF‚ enableä telló ZMÄ programó tï calculatå thå amounô oæ 
     memorù  availablå  foò  routineó  usinç  DBUÆ  disë  buffer®  
     OUTSIÚ  wilì adjusô accordinç tï thå contentó oæ locatioî  ¶ 
     anä 7®  Iæ BYÅ ió running¬ thió valuå ió useä aó is¬ elså iæ 
     BYÅ  ió NOT‚ running¬  0806È ió subtracteä froí thió  addresó 
     locatioî ¶ anä 7®   Iî eitheò case¬ thå enä oæ prograí valuå 
     determineä aô timå oæ assemblù ió subtracteä froí thå resulô 
     oæ  thå abovå tï situations®   Leftoveò byteó iî Ì arå  theî 
     discardeä tï leavå aî eveî pagå boundary.


     ------------------------------------------------------------
     NOTEº   MOSÔ  ALÌ systemó wilì benefiô witè STDBUÆ  enabled¬ 
     sincå  maximuí  numbeò oæ uploadó alloweä iî  batcè  receivå 
     modå  ió directlù relateä tï thå amounô oæ memorù available®  
     However¬ Iæ youò systeí useó memorù locateä belo÷ thå CCĞ oò 
     BYÅ program¬  yoõ wilì neeä tï disablå this¬  iî whicè  caså 
     OUTSIÚ  wilì bå seô tï 16ë nï matteò what®   Iæ youò  systeí 
     hangó   oò   behaveó  strangelù  durinç   descriptioî   filå 
     read/writå operations¬ disablå thió - trù iô enableä first.
     ------------------------------------------------------------

.paŠ
     3.3       Timekeeping

     3.3.1     BYE Clock Support

     CLOCK‚  enableä  wilì  allo÷ ZMÄ anä  utilitieó  tï  looë  aô 
     clocë  anä datå informatioî retrieveä bù BYÅ  (BYE5¬  MBYEnî 
     anä MBYE44« witè extendeä BDOÓ enabled© froí youò systeí anä 
     storeä  iî  higè  memory®  Thå addresó oæ thió  higè  memorù 
     buffeò ió calculateä aó thå addresó aô (JĞ COLBOOT+25)®   Iæ 
     yoõ seô thió tï YES¬ thå followinç informatioî ió retrieved:


           Location           Contents                Range
         +------------------+-----------------------+-------+
         | (JP COLDBOOT+24) | Maximum time allowed  | 0-255 |
         | (JP COLDBOOT+25) | LSB of RTCBUF address | ----- |
         | (JP COLDBOOT+26) | MSB of RTCBUF address | ----- |
         +------------------+-----------------------+-------+

         +------------------+-----------------------+-------+
         | (RTCBUF+0)       | Current hour          | 0-23  |  
         | (RTCBUF+1)       | Current minute        | 0-59  |
         | (RTCBUF+2)       | Current seconds       | 0-59  |
         | (RTCBUF+3)       | Current century       |  19   |
         | (RTCBUF+4)       | Current year          | 0-99  |
         | (RTCBUF+5)       | Current month         | 1-12  |
         | (RTCBUF+6)       | Current day           | 1-31  |
         | (RTCBUF+7©       | LSB oæ TOS            | 0-255 |
         | (RTCBUF+8©       | MSB oæ TOS            | ----- |
         +------------------+-----------------------+-------+

     Clock/datå  readeò codå insertó arå noô supporteä undeò thió 
     configuration®  ZMÄ programó supporô alì clock/datå featureó 
     witè  thió switcè enableä anä clock/datå readeò codå  ió  iî 
     BYE® 


     3.3.2      ZMD Internal Clock/Date Reader Code

     RTC‚  shoulä bå enableä iæ yoõ cannoô takå advantagå oæ BYE'ó 
     RTCBUÆ  explaineä abovå anä yoõ wisè tï includå youò  systeí 
     specifiã  clocë anä datå readeò codå aô labeì RTCTIÍ iî  thå 
     ZMDHDR.Z8°   configuratioî table®  Bå surå tï initializå alì 
     byteó  witè binarù valueó (seå Range‚ columî iî  tablå  3.3.±  
     foò  minimuí anä maximuí values)®   BCDBIÎ maù bå  requesteä 
     froí  ZMDSUBS.REÌ tï converô binarù codå decimaì valuå iî  Á 
     registeò  tï  binarù valuå iî Á register®  Deletå alì  ';<=§ 
     lineó  afteò youò codå  ió installed®   Thió concepô ió  noô 
     valiä  iæ CLOCË switcè ió  enableä anä BYÅ ió  runninç  witè 
     clocë anä datå readeò codå installed.

     NOTEº   Makå  surå yoõ dï noô overruî thå modeí I/Ï  patcè 
     area when you insert your clock code.
.paŠ
     3.3.3      Restricting Downloads to Time Left

     TIMEON‚ switcè enableä telló ZMÄ tï restricô downloadó tï thå 
     calleró  timå  lefô  oî system®   Iæ CLOCË  ió  enableä  anä 
     MBYE/BYEµ  ió running¬   BYE'ó maximuí timå alloweä bytå (JĞ 
     COLDBOOT+24©  ió useä foò comparison®   Iæ CLOCË ió  NÏ  (oò 
     MBYE/BYE5©  anä RTÃ ió yes¬  MAXTOÓ shoulä bå pokeä bù  youò 
     RTÃ  insert®   Iæ CLOCË anä RTÃ arå botè NO¬  MAXMIÎ wilì bå 
     useä  aó  á defaulô anä incrementeä oò decrementeä  aó  filå 
     transferó occur.


     3.3.4      Maximum Minutes Allowed

     MAXMIN‚  shoulä  bå seô tï youò likinç iæ CLOCË anä  RTÃ  arå 
     botè NO¬ anä TIMEOÎ ió YES®  Thió valuå wilì bå thå default®  
     Thió ió decremented/incrementeä eacè timå á filå transfeò ió 
     madå  anä  thå  calleò  ió loggeä ofæ  wheî  iô  reacheó  0®  


     3.3.5      Display Time on System Messages

     DSPTIM‚ ió seô YEÓ tï havå timå oî systeí messageó  displayeä 
     aô thå starô anä exiô oæ ZMD®  Iæ CLOCË ió YES¬ anä MBYE/BYÅ 
     ió  running¬  TOÓ ió gotteî froí BYE'ó TOÎ worä (iî RTCBUF)®  
     Iæ  CLOCË ió NO¬  oò MBYE/BYEµ ió noô running¬  thå  currenô 
     minuteó  alloweä  ió subtracteä froí thå originaì  valuå  oæ 
     MAXMIÎ aô prograí startup®   Thå resulô ió displayeä aó timå 
     on®  Thió value ió actuallù á tallù:
     
      Original MAXMIN + upload time - download time = time on


     3.3.6      Logon Hour/Minute Addresses

          LHOUR‚  ió thå addresó oæ thå caller'ó logoî  houò  bytå 
     seô  bù  youò  BYÅ oò BBÓ prograí wheî thå calleò  logó  on®  
     LHOUR+² ió thå logoî minute®  Botè valueó containeä iî theså 
     addresseó  shoulä bå iî binary®   Thió shoulä onlù bå seô iæ 
     RTÃ anä eitheò TIMEOÎ oò DSPTOÓ arå seô YES®  (Noô useä witè 
     CLOCK).
.paŠ
     3.4        Access Restrictions

     3.4.1      ZCMD/ZCPR

     ZCPÒ (biô ° iî ACCMAP© shoulä bå seô tï YEÓ iæ yoõ intenä oî 
     monitorinç  WHEEÌ bytå statuó oò neeä tï restricô  receivinç 
     SYS¬  RCP¬  NDÒ filå types®  Iæ thió biô ió seô NO¬ WHEEÌ ió 
     alwayó 0.
 

     3.4.2      WHEEL Byte

     WHEEÌ bytå togglå ió foò verù speciaì users®  Iæ ZCPÒ ió seô 
     tï YES¬   ZMÄ wilì monitoò thå bytå locateä aô thió address®  
     Iæ it'ó 0¬ time¬ drive/user/filenamå anä accesó restrictionó 
     remaiî iî force®  Iæ thió bytå ió non-zero¬ alì restrictionó 
     are bypassed.


     3.4.3      Maximum Drive/User

     USEMAØ  shoulä  bå seô tï YEÓ iæ yoõ wanô tï uså ZCPR'ó  lo÷ 
     memorù  byteó tï keeğ tracë oæ maximuí drivå anä user®   ZMÄ 
     wilì  uså  thå valueó aô locationó DRIVMAØ  anä  USRMAØ  foò 
     maximuí  drive/user®   Iæ USEMAØ ió NO¬  hardcodå MAXDRÖ anä 
     MAXUSÒ tï youò owî requirements.


     3.4.4      BYE/BBS Program Access Flag Byte

     ACCESÓ  iæ  enabled¬   telló ZMÄ thaô youò BYE/BBÓ  softwarå 
     supporô  aî  accesó  flagó  register®   Thió  flaç  registeò 
     (AFBYTE©  ió ± datá bytå iî lengtè anä containó ¸ flaç  bitó 
     correspdondinç  tï commoî BBÓ restrictions®   ZMÄ caî  checë 
     thió  registeò  beforå  allowinç thå 'RM§ optioî  tï  uploaä 
     preformatteä messagå fileó tï youò BBS'ó messagå base¬ oò tï 
     uså  thå  'RW§ optioî foò 'privilegeä user§  uploaä  withouô 
     beinç requireä tï givå uploaä descriptions®  Iæ enabled¬ seô 
     ACCOFÆ  tï  reflecô thå numbeò oæ byteó froí JĞ COLDBOOÔ  tï 
     AFBYTÅ  flagó byte®  ZMÄ inspectó AFBYTÅ foò  thå  followinç 
     flaç data:


		Bit:    7 6 5 4 3 2 1 0
			| | | | | | | |
     Privileged user ---* | | | | | | |
	      Uploaä -----ª ü ü ü ü ü ü  ª Oæ theså bits¬ onlù 3¬ 
	    Downloaä -------ª ü ü ü ü ü    5¬ ¶ anä · arå useä bù 
	        CP/Í ---------« ü ü ü ü    ZMD®   Biô numberó arå 
	       Writå -----------ª ü ü ü    poweró oæ 2¬  witè biô 
		Reaä -------------« ü ü    °  beinç   thå   leasô 
		 BBÓ ---------------« ü	   significanô biô oæ thå 
	      System -----------------+    byte.
.paŠ
     3.5        Upload Configurations

     3.5.1      Preformatted BBS Message Uploads

     MSGFIÌ  switcè  enableó ZMÄ tï accepô  preformatteä  messagå 
     filå  uploads®  Fileó uploadeä witè thå 'RM§ optioî wilì  bå 
     forwardeä  tï  thå  drive/useò defineä aô PRDRÖ  anä  PRUSR®  
     Thió uploaä ió theî appendeä tï youò BBÓ messagå base®  Youò 
     BBÓ  softwarå  anä  BYÅ prograí musô supporô  thió  feature® 
     MBBÓ, QBBS and PBBS all support this feature.   PMSG/HMSG is
     now available on RI RCPM-RDOS.


     3.5.2      Hiding New Uploads Until Approved by Sysop

     HIDEIÔ allowó Sysopó tï keeğ alì ne÷ regulaò uploadó  hiddeî 
     froí  publiã viewinç untiì revieweä anä cleared®   Thió way¬  
     ne÷  uploadó  wilì  noô appeaò iî á  DIRectorù  listinç  anä 
     cannoô bå vieweä oò eveî downloadeä bù ZMD®  Thió featurå ió 
     disableä wheî thå WHEEÌ bytå ió OÎ oò Privatå uploaä modå ió 
     enabled®   Fileó  thaô  havå beeî hiddeî wilì sho÷ uğ  iî  á 
     DIRectorù listinç wheî thå WHEEÌ bytå ió seô anä á $Ó optioî 
     ió  useä  tï sho÷ SYSTEÍ files®   Referencå wilì bå madå  tï 
     theså  fileó iî thå loç anä FOÒ texô filå listingó iæ  thoså 
     featureó  arå enabled®   Yoõ caî uså POWEÒ oò NSWEEĞ tï  seô 
     hiddeî fileó tï $DIR.


     3.5.3      Upload Routing to Multiple Drive/Users

     ASKAREÁ  switcè seô YEÓ enableó uploaä routinç  tï  multiplå 
     drive/useò areas®   Witè thió enableä á calleò ió  displayeä 
     á lisô oæ uploaä categorieó tï chooså from®   Wheî hå enteró 
     hió selection¬  ZMÄ wilì calculatå thå offseô tï thå  uploaä 
     drive/useò  iî TYPTBÌ  anä seô thå uploaä areá baseä oî  hió 
     selection®   Thió ió donå aô thå samå timå foò botè  Regulaò 
     anä Privatå uploads)®    Uploaä routinç ió disableä wheî thå 
     WHEEÌ bytå ió set¬ iî whicè case¬  normaì uploadó wilì gï tï 
     thå  currenô drive/useò areá anä privatå uploadó wilì gï  tï 
     thå drive/useò equateä aô PRDRÖ anä PRUSR.


     3.5.4      Uploading to Specified Drive/User

     SETAREÁ  enableä  forceó alì ne÷ uploadó tï  thå  drive/useò 
     defineä aô DRV‚ anä USR®   Iæ thå WHEEÌ bytå ió set¬  regulaò 
     uploadó wilì gï tï thå currenô oò specifieä drive/user®  Alì 
     privatå  fileó uploadeä witè thå 'RP§ optioî wilì bå senô tï 
     PRDRÖ anä PRUSÒ regardlesó oæ WHEEÌ status.

.paŠ
     3.5.5      Receiving Private Uploads

     PRDRÖ anä PRUSÒ arå thå drive/useò areá wherå ALÌ fileó senô 
     tï  thå Sysoğ witè thå 'RP§ optioî wilì gï  (unlesó  ASKAREÁ 
     ió YES)® Thió permitó experimentaì files¬ replacemenô and/oò 
     proprietarù  programó tï bå senô tï aî areá onlù  accessiblå 
     bù  thå  Sysop®  Thió ió alsï thå drivå anä useò areá  wherå 
     messagå  fileó  arå  uploaded¬  iæ MSGFIÌ ió  seô  YES®   Iæ 
     ASKAREÁ ió YES¬  'RP§ uploadó wilì gï herå onlù iæ thå WHEEÌ 
     ió set®  Iæ MSGDESÃ ió YES¬  thió ió thå drivå anä useò areá 
     thå FOÒ texô filå wilì bå placeä beforå appendinç iô tï  thå 
     BBÓ system'ó messagå base.


     3.5.6      Crediting Upload Time to Time Left

     CREDIÔ  enableä  causeó ZMÄ tï crediô calleró foò  thå  timå 
     theù  spenä  uploadinç non-privatå fileó eacè  session®  Foò 
     example¬  á  calleò whï spendó 3° minuteó sendinç aî  uploaä 
     getó  3° minuteó addeä tï hió TLOS®   (Yoõ musô  seô  eitheò 
     CLOCK¬ RTÃ oò TIMEOÎ tï YEÓ tï uså thió feature).


     3.5.7     Receiving .COM Files Securely

     NOCOMÒ  telló ZMÄ tï renamå .COÍ fileó tï .OBÊ anä  .PRÌ  tï 
     .OBĞ  oî  receive®   Thió featurå ió alsï disableä wheî  thå 
     WHEEÌ bytå ió set.

.paŠ
     3.6        Upload Descriptions

     Thió sectioî haó tï dï witè uploaä descriptions®   Iæ yoõ dï 
     noô intenä oî implementinç uploaä descriptions¬  seô DESCRIÂ 
     anä  MSGDESÃ  tï  NO®  Thå resô oæ  theså  valueó  arå  theî 
     ignored®   Iæ  usinç descriptions¬  seô ONLÙ onå oæ theså tï 
     YES¬ noô both.


     3.6.1      Forwarding Descriptions to BBS Message Base

     MSGDESÃ  shoulä bå seô YEÓ iæ youò youò BBÓ systeí  supportó 
     messagå  uploads¬  anä yoõ prefeò uploaä descriptionó tï  bå 
     placeä iî youò BBÓ messagå baså (seô DESCRIÂ NO)® MBBÓ useró 
     neeä  tï instalì MFMSG.COÍ witè thå MBBSINIÔ program®   Theî 
     seô  youò BYÅ prograí tï kno÷ abouô messagå filå uploadó  bù 
     settinç thå MSGFIÌ optioî iî BYE/MBYÅ tï YES®   Iæ seô  YES¬ 
     ZMÄ  wilì  producå  á  FOÒ texô  filå  wheî  writinç  uploaä 
     descriptions®  Thió  FOÒ filå wilì gï tï thå drivå anä  useò 
     areá  equateä aô PRDRÖ anä PRUSÒ jusô beforå beinç  appendeä 
     tï youò BBÓ system'ó messagå base.


     3.6.2      Forwarding Description to FOR Text File

     DESCRIÂ  switcè shoulä bå YEÓ iæ yoõ wanô descriptionó tï bå 
     appendeä tï thå currenô FOÒ filå wherå theù caî bå vieweä bù 
     calleró   witè  thå  ZFORĞ  utility®   Sysoğ  caî  adä   ne÷ 
     descriptionó  witè thå ZFORÓ utility®   Uploadó senô tï  thå 
     Sysoğ privatå uploaä areá wilì noô requirå descriptions¬ noò 
     wilì  fileó uploadeä witè thå 'RW§ optioî - useò musô  bå  á 
     privilegeä  useò  (biô · iî ACCESÓ bytå set© oò  havå  WHEEÌ 
     accesó anä PUPOPÔ musô bå seô YEÓ tï uså thå 'RW§ option.


     3.6.3      Description Filename

     FORNAM/DRIVE/USEÒ  ió thå drive/useò anä filenamå oæ thå FOÒ 
     descriptioî  texô  file®   Thió filenamå musô  bå  1±  byteó 
     paddeä witè spaces®  Iæ usinç witè DESCRIÂ seô YES¬ yoõ musô 
     indicatå  whaô  drive/useò  yoõ wanô thå 'FOR§  filå  tï  bå 
     placed®   Drive/useò areá ió automaticallù changeä tï  PRDRÖ 
     anä  PRUSÒ  iæ descriptionó arå tï bå forwardeä tï  thå  BBÓ 
     messagå baså 

.paŠ
     3.6.4      Upload Description Header Information

     Iæ  youò configuratioî includeó DESCRIÂ seô tï  YES¬  you'lì 
     havå  tï telì ZMÄ whaô informatioî yoõ wanô includeä iî  thå 
     firsô linå oæ eacè description®  Codå ió includeä iî alì ZMÄ 
     programó  tï  placå  alì  (any© informatioî  iî  thå  uploaä 
     descriptioî header® Thå followinç diagraí illustrateó á fulì 
     implementatioî oæ DESCRIB:


     -----
     ZMD150.LBR - Communications         (C3:)     Rcvd: 09/29/88
		      /			   /		  /
      	      _______/		   _______/	    _____/
       ASKIND 	             INCLDU 	      DSTAMP



     3.6.5      Including File Descriptors

     ASKINÄ  switcè  enableä causeó ZMÄ programó tï asë  foò  thå 
     categorù  oæ  thå  upload(s© anä writå iô  intï  thå  uploaä 
     descriptioî header®   Iæ yoõ seô thió tï YES¬  makå surå yoõ 
     seô  MAXTYĞ tï thå highesô letteò choicå yoõ wisè tï supporô 
     anä ediô thå texô aô KNDTBÌ uğ tï anä includinç youò  MAXTYĞ 
     setting® (Useä onlù witè DESCRIB).


     3.6.6      Including Upload Drive/User Area

     INCLDÕ  enableä  wilì  includå thå drive/useò  areá  oæ  thå 
     uploadeä filå intï thå uploaä descriptioî header® (Useä onlù 
     witè DESCRIB).


     3.6.7      Datestamping the Description Header

     DSTAMĞ enableä wilì includå thå datå thå uploaä waó receiveä 
     intï thå uploaä descriptioî header®   (NÏ iæ nï clock© (Useä 
     onlù witè DESCRIB).


     3.6.8      Overriding Description requests

     PUPOPÔ  allowó descriptionó tï bå disableä wheî "RW¢ ió useä 
     oî thå ZMÄ commanä linå (i.e® ZMÄ R× FILE.EXT)® Thió commanä 
     maù  onlù bå useä bù thoså considereä "priviledged¢ useró oî 
     youò  systeí oò WHEEÌ users®   Uploadó oæ thió typå wilì  bå 
     taggeä iî thå ZMD.LOÇ filå aó private¬  sï aó noô tï displaù 
     witè thå NE× command®   (Seå ACCESÓ equatå descriptioî abovå 
     foò informatioî oî detecting 'priviledged§ users).

.paŠ
     3.6.9      Automatic Word Wrap

     WRAĞ  ió  seô tï thå columî positioî wherå  worä  wrağ  wilì 
     occur®   Iæ usinç MSGDESÃ anä havå problemó witè aî 'Invaliä 
     format§ erroò froí MFMSG.COM¬  trù settinç WRAĞ tï somethinç 
     smaller¬   likå 6² oò 63®  (Worä wrağ caî bå disableä bù thå 
     useò  witè ^× durinç descriptioî entry®   Enteò 7²  herå  tï 
     disablå WRAĞ completely).

.paŠ
     3.7        Download Configurations

     ACCMAĞ  ió á biô mappeä flaç registeò ± bytå iî length®   Iô 
     containó  ¸  flaç  bitó whicè  enable/disablå  thå  filenamå 
     restrictionó  outlineä  below®    Thå  restrictionó   alwayó 
     pertaiî tï thå filå beinç considereä foò transfer®  Enablinç 
     anù  oæ theså optionó causeó ZMÄ tï looë aô thå higè biô  oæ 
     thå  bytå  positioî  indicateä belo÷  (F1=filenamå  bytå  1¬ 
     T2=filå  typå bytå 2¬  etc)®   Theså restrictionó arå alwayó 
     bypasseä wheî usinç ZCPÒ anä thå WHEEÌ ió set.


     3.7.1      Restricting .LBR and Single F1 Tagged Files

     TAGFIL‚  switcè  ió enableä iæ yoõ wanô tï  restricô  calleró 
     froí downloadinç certaiî files¬  sucè aó verù largå  overlaù 
     libraries¬  gamå libraries¬  etc®   Iî mosô cases¬ remaininç 
     timå  lefô  oî  systeí woulä bå sufficienô  foò  restrictinç 
     downloads®  However¬ witè biô · oæ ACCMAĞ seô tï 1¬ ZMÄ wilì 
     checë  thå  higè biô oæ filenamå bytå ± anä iæ thió ió  set¬ 
     thå  filå  maù  noô  bå  downloaded®    Iæ  thå  filå  ió  á 
     ARK/ARC/LBÒ  file¬  individuaì  memberó  maù  bå  downloadeä 
     however®   Thió restrictioî ió bypasseä iæ thå WHEEÌ bytå ió 
     set.

          ACCMAP Switch:  10000000
          Filename Byte:  FILENAME.EXT
     

     3.7.2      Disallowing .COM Downloads

     NOCOMÓ  shoulä bå enableä iæ yoõ dï noô wanô calleró  tï  bå 
     ablå  tï  downloaä *.COÍ files®   Mosô securå  systemó  wilì 
     enablå  thió  restriction®   Thió featurå ió  bypasseä  wheî 
     WHEEL byte is set.

          ACCMAP Switch:  00001000
          Filename Byte:  FILENAME.EXT


     3.7.3      Disallowing .??# Downloads

     NOLBÓ ió enableä foò thoså systemó whicè uså 'labels§ iî thå 
     thirä  filå  extenô bytå oæ systeí fileó tï restricô  publiã 
     accesó tï them® ZMÄ wilì checë T³ bytå foò á '#§ characters®  
     Upoî  á  match¬  thå downloaä ió denied®   Thió  featurå  ió 
     bypassed when the WHEEL byte is set.

          ACCMAP Switch:  00010000
          Filename Byte:  FILENAME.EXT

.paŠ
     3.7.4      Disallowing F2 Tagged $SYStem File Downloads

     NOSYÓ  enableä telló ZMÄ tï ignorå alì fileó witè  thå  higè 
     biô seô iî filenamå bytå T2®   Theså fileó arå considereä aó  
     hiddeî $SYSteí fileó bù CP/Í anä caî bå treateä thå samå waù 
     bù ZMD® Thió featurå ió bypasseä wheî thå WHEEÌ bytå ió set.

          ACCMAP Switch:  00100000
          Filename Byte:  FILENAME.EXT


     3.7.5      Sending F3 Tagged Files Regardless of Access

     DWNTAÇ  iæ enableä allowó anù filå witè thå higè biô seô  iî 
     filenamå bytå ³ tï bå senô regardlesó oæ thå calleró access. 
     Thió comeó iî verù handù foò closeä systemó requirinç  useró 
     tï  downloaä  applications¬  systeí informatioî  files¬  BBÓ 
     lists, etc.

          ACCMAP Switch:  01000000
          Filename Byte:  FILENAME.EXT


     3.7.6      Special Sysop Downloads to Selected Caller

     SPDRÖ  anä SPUSÒ contaiî thå drive/useò areá foò downloadinç 
     privatå  'SP§ fileó froí Sysop®   Thió permitó you tï puô  á 
     speciaì 'non-public§ filå iî thió area¬ theî leavå á privatå 
     notå tï thå persoî iô ió intendeä foò mentioninç thå namå oæ 
     thå  filå anä ho÷ tï downloaä it®   Althougè anybodù 'could§ 
     downloaä thaô program¬  theù don'ô kno÷ whaô (iæ any©  fileó 
     arå  there®   Á higè degreå oæ securitù exists¬   whilå  thå 
     Sysoğ stilì haó thå abilitù tï makå speciaì fileó available® 
     Thuó anù persoî caî bå á temporarù 'privilegeä user'.

     NOTEº Á breacè oæ securitù existó iæ SPUSÒ ió noô defineä aó 
     á  higheò useò areá thaî thå maximuí allowablå  publiã  useò 
     area.‚ 

.paŠ
     3.8        Logkeeping

     Á clocë ió not necessary for this logkeeping features.


     3.8.1      Making ZMD.LOG File

     LOGCAL‚ enableó thå loç keepinç routineó iî ZMD®  Ne÷ uploadó 
     wilì bå addeä tï thå currenô ZMD.LOÇ file®   Iæ nï loç  filå 
     exists¬ onå wilì bå created®  Alì filå transferó arå logged®  
     Yoõ  caî  theî  uså  ZNEWP.COÍ tï sho÷  listingó  oæ  recenô 
     uploadó oò ZNEWÓ tï adä loç entries.


     3.8.2      European Date Format (DD/MM/YY)

     EDATE‚  causeó  ZMÄ anä utilitieó tï sho÷  datå  iî  dd/mm/yù 
     formaô insteaä oæ mm/dd/yù format.


     3.8.3      Transfer Log Drive/User/Filename

     LOGNAM/LOGDRV/LOGUSR‚  ió thå drive/useò anä filenamå oæ  thå 
     ZMD.LOÇ  filå transfeò log®   Thió filenamå musô bå 1± byteó 
     paddeä witè spaces®   Iæ usinç witè LOGCAÌ seô YES¬ yoõ musô 
     indicatå  whaô drive/useò yoõ wanô thå 'ZMD.LOG§ filå tï  bå 
     placed®


     3.8.4      LASTCALR Drive/User

     LASTDRV/LASTUSR/LCNAME‚  ió thå drive/useò oæ youò BBÓ oò BYÅ 
     program'ó LASTCALR.??¿ file®  Thió filenamå musô bå 1± byteó 
     paddeä witè spaces®   Iæ usinç witè LOGCAÌ seô YES¬ yoõ musô 
     indicatå whaô drive/useò ZMÄ caî finä thå LASTCALR.??¿ file® 
     LCNAMÅ shoulä bå seô tï thå columî positioî oæ thå  caller'ó 
     namå iî thå LASTCALR.??¿ file®  (° foò PBBS¬ 1± foò MBBS).


     3.8.5      Counting Files Transfers for BBS Software

     LGLDS‚  seô YEÓ enableó sessioî uploaä anä downloaä counting® 
     ZMÄ  wilì counô thå numbeò oæ up/downloadó foò  eacè  logon®  
     Youò  BBÓ  prograí theî caî checë UPLDS‚  anä  DNLDS‚  counteò 
     byteó wheî á useò logó ouô anä updatå eitheò thå user'ó filå 
     oò á filå foò thió purpose®   Yoõ caî eitheò modifù youò BBÓ 
     entrù prograí tï checë thå LASTCALÒ filå beforå updatinç anä 
     theî  updatå  (risky)¬  oò makå á separatå prograí thaô  BYÅ 
     calló wheî logginç ofæ á useò (preferred)®   (YEÓ foò PBBS)®  
     Don'ô forgeô tï initializå UPLDÓ anä DNLDÓ counteò byteó  tï 
     ° froí youò BBÓ prograí wheî somebodù logó in.

     NOTEº  Cleaò  thå UPLÄ anä DNLÄ byteó ONLÙ wheî á useò  logó 
     in¬ noô wheî hå re-enteró thå BBÓ prograí froí CP/M.Š






















                            APPENDICES

.paŠ
     A.1        Modem Interface

     A.1.1      Creating ZMD Modem Input/Output Overlays

     Alì  port/modeí overlayó arå alloweä 12¸ byteó betweeî  580È 
     anä 5FFH®   Thió areá ió alwayó containeä iî thå  ZMDHDR.Z8° 
     configuratioî   tablå  anä  includeä  durinç  thå   assemblù 
     process®  Thå firsô 27 byteó oæ thió overlaù musô contaiî  ¸ 
     JĞ instructionó iî thå followinç order:


       Routine  Purpose                      Entry    Exit
       --------------------------------------------------------
       CONOUT   Local console output (BIOS)  A=char   -----
       INIT     Initialization               -----    -----
       UNINIT   Uninitialization             -----    -----
       SNDCHR   Send character  POP AF gets->A=char   -----
       CARCHË   Carrier check                -----    Z=Carrier
       GETCHÒ   Receive a character          -----    Char in A
       RCVRDÙ   Check receive ready          -----    Z=char
       SNDRDÙ   Check send ready             -----    Z=ready


     A.1.2      Installing Your Modem I/O Overlays

     ZMÄ musô havå accesó tï youò modeí foò obviouó reasons®   Iô 
     needó tï senä data¬  receivå data¬  perforí erroò  checking¬ 
     monitoò  carrieò  anä givå controì bacë tï youò BYÅ  prograí 
     wheî  carrieò  ió lost®   Iô haó tï kno÷ wheî thå  modeí  ió 
     readù  tï  senä  anotheò  characteò anä wheî  onå  haó  beeî 
     received®  Iæ youò systeí useó extendeä BDOÓ calló tï accesó 
     youò BYÅ programó port/modeí routines¬  yoõ caî instalì  ZMÄ 
     anä  utilitieó withouô regarä tï thió  section®   Otherwise¬ 
     follo÷ these steps:

        1©   Finä aî overlaù froí ZMDOVLn.LBÒ thaô besô fitó youò        
             modem/porô requirements®  Yoõ maù havå tï creatå onå 
             foò youò systeí iæ  onå doesn'ô exisô already®  Some
             standarä  formató arå includeä (seå -OVERLAY.LSÔ  iî 
             the ZMDOVLn.LBR).
        2©   Ediô iô witè  youò favoritå wordprocessoò aó needed® 
             Makå  surå yoõ locaì consolå outpuô  addresó  (BIOS© 
             caî bå calculateä usinç standarä CP/Í methodó  (i.e®
             (JĞ  COLDBOOT+9©  Iæ  youò BIOÓ JĞ  TABLÅ  haó  beeî         
             altered¬  yoõ  wilì havå tï providå thió addresó foò    
             ZMÄ  aô labeì CONOUT®   Iî mosô cases¬  ZMÄ wilì  bå 
             ablå tï calculatå thió addresó foò you®  Iæ yoõ wilì 
             neeä  tï  initializå anythinç aô prograí  starô  up¬ 
             includå  youò custoí routinå aô labeì INIÔ anä  youò         
             uninitializå  routinå aô UNINIT®   INIÔ ió calleä aô         
             prograí startup¬   anä oæ courså UNINIÔ ió calleä aô         
             prograí exit.
.paŠ        3©   Assemblå witè M80¬ oò SLRMAÃ oò otheò Z8° compatiblå 
             assembler to produce ZMxx-n.HEX
        4©   Uså MLOAÄ (included© tï loaä ZMxx-n.HEØ oveò ZMD.COÍ 
             likå this:

              A0>MLOAD ZMD=ZMD.COM,ZMxx-n


     ZINSTÌ wilì no÷ recognizå youò modeí overlay®   Yoõ caî alsï 
     uså  DDÔ tï patcè youò overlaù in®   Makå surå iô startó  aô 
     580H and ends by 5FFH (128 bytes).

     NOTEº   Iæ ZMÄ attemptó tï seô thå currenô useò areá tï  24± 
     anä 7· ió returneä iî registeò A¬  BYE'ó extendeä BDOÓ calló 
     will be used for modem I/O.  
.paŠ
     B.1        RTC Clock/Date Reader Code

     Á fe÷ oæ ZMD'ó nicå featureó arå dependenô upoî accesó tï  á 
     Reaì Timå Clock®   MBYÅ anä BYEµ useró whï havå theiò  clocë 
     anä  datå  readeò codå installeä neeä onlù seô CLOCË tï  YEÓ 
     anä  leavå RTÃ seô NO®   Iæ oî thå otheò hanä youò BYÅ  doeó 
     noô  reaä youò systeí clock¬  yoõ wilì havå tï  inserô  youò 
     clocë  anä  datå readeò codå aô labeì RTCTIÍ iî  ZMDHDR.Z80®  
     Witè  RTÃ  seô  YES¬  alì ZMÄ routineó havå  accesó  tï  thå 
     followinç binary valueó (pokeä bù youò clocë insert):


                    Address   Length   Range
                  +---------+--------+-------+
                  | MONTH   | 1 byte | 1-12  |
                  | DAY     | 1 byte | 1-31  |
                  | YEAR    | 1 byte | 0-99  |
                  | HOUR    | 1 byte | 0-23  |
                  | MINUTE  | 1 byte | 0-59  |
                  +---------+----------------+ 


     Youò inserô musô starô aô 4FEÈ anä enä bù 57FÈ (13° bytes).
.paŠ
     C.1        File Descriptors/Categories

     Thió  tablå  defineó  thå  texô tï  bå  includeä  iî  uploaä 
     descriptioî  headeró  (DESCRIÂ  anä ASKIND©  and/oò  defineó 
     categorieó  foò uploadinç tï multiplå drive/useò  areaó  (Iæ 
     ASKAREA)®   Changå aó desired¬ iæ thió lisô ió noô suitable®  
     Dï  NOÔ  removå anù oæ thå texô aô KNDTBL®  Simplù ediô  thå 
     categorù  texô  belo÷ uğ to/includinç youò  MAXTYĞ  setting® 
     MAXTYP‚  belo÷  musô bå seô tï whateveò letteò  youò  maximuí 
     choicå wilì be® 


     MAXTYP:	DB	'W'	; Highest category you will support.
 
     KNDTBL:

     DB   '  A) - CP/M Utility          ',CR,LF
     DÂ   '  B© - CP/Í Applicatioî      ',CR,LF
     DÂ   '  C© - CP/Í Gamå             ',CR,LF
     DÂ   '  D© - Wordprocessinç        ',CR,LF
     DB   '  E) - Text & Information    ',CR,LF
     DB   '  F) - Printer Related       ',CR,LF
     DB   '  G) - Communications - IMP  ',CR,LF
     DB   '  H) - Communications - MEX  ',CR,LF
     DB   '  I) - Communications - Other',CR,LF
     DB   '  J) - RCP/M Software        ',CR,LF
     DB   '  K) - BBS List              ',CR,LF
     DB   '  L) - ZCPR1/2/3             ',CR,LF
     DB   '  M) - Pascal Utility/Source ',CR,LF
     DB   '  N) - dBase Utility/Source  ',CR,LF
     DB   '  O) - Basic Utility/Source  ',CR,LF
     DB   '  P) - ''Other'' Language      ',CR,LF
     DB   '  Q) - EPSON Specific        ',CR,LF
     DB   '  R) - ZMD Support           ',CR,LF
     DB   '  S) - IBM Utility           ',CR,LF
     DB   '  T) - IBM Application       ',CR,LF
     DB   '  U) - IBM Game              ',CR,LF
     DB   '  V) - IBM Communications    ',CR,LF
     DB   '  W) - Mixed Batch/Misc      ',CR,LF
     DB   '  X) - <<<< Not Defined! >>>>',CR,LF
     DB   '  Y) - <<<< Not Defined! >>>>',CR,LF
     DB   '  Z) - <<<< Not Defined! >>>>',CR,LF
     DB	  0		; leave the table terminator alone.


     ------------------------------------------------------------
     NOTEº   Makå surå yoõ leavå alì thå categorieó abovå EXACTLÙ 
     3±  byteó lonç  (2¹ byteó oæ texô pluó thå CR,LÆ equaló  31© 
     oò yoõ wilì havå problemó witè thå doublå columî  formattinç 
     routines.
     ------------------------------------------------------------
.paŠ
     D.1        Upload Routing Table

     Iæ  yoõ decideä tï enablå uploaä routinç tï  multiplå  drivå 
     users¬ yoõ wilì havå tï seô thå followinç tablå foò youò owî 
     requirements®  Ediô  alì areaó aô TYPTBÌ uğ tï anä includinç 
     youò  MAXTYĞ  setinç  tï matcè thå messagå  texô  iî  KNDTBÌ 
     above®  Notå thaô PRIVATÅ uploadó maù bå senô tï á differenô 
     drivå  aó  welì aó á differenô useò  area®   Eacè  entrù  ió 
     expresseä aó 'drivå letter',useò area®  Simplù seô MAXTYĞ tï 
     thå  highesô letteò choicå supported®   (Dï NOÔ commenô  ouô 
     anù oæ theså storagå bytes).

                     _________
       NOTE:        /    A    \	 <--- Corresponds to category 'A'
                   'A',1,'B',15,
                     \ /   \ /
      Normal upload --+     |
      Private upload -------+


     TYPTBL:
	    _________     _________     _________     _________
	   /    A    \   /    B    \   /    C    \   /    D    \
     DB	  'A',1,'B',15, 'A',2,'B',15, 'B',2,'B',15, 'B',4,'B',15
	    _________                   _________
	   /    E    \                 /    Z    \
     DB	  'B',3,'B',15, ... thru ...  'B',7,'C',12


