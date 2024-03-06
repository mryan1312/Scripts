# Loading windows forms assembly
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Load data source into hash table



function Get-Results($Term) {
    $DataSource = @{code="company"; 139="affordable medical supplies"; 23="armor bank"; 5="baltz feed company"; 7="bank of cave city"; 82="bank of mccrory"; 126="bank of salem"; 10="cache river valley seed"; 168="central bank"; 169="century finance"; 12="childrens homes inc"; 158="citizens bank"; 123="city youth ministries"; 181="cme inc"; 96="concordia christian academy"; 155="craighead county"; 156="craighead county sherrif's office"; 16="d and l incorporated"; 109="darling store fixtures"; 194="davidson drug"; 103="denver's refrigeration"; 94="dermatology office"; 172="dudley bowden cpa"; 163="e & rrr produce"; 143="east arkansas area agency on aging"; 186="edgar electric inc"; 66="eldridge supply company"; 141="engines inc"; 146="epmh"; 38="era doty real estate"; 95="fannin bank"; 177="farmer enterprises inc"; 18="farmers bank and trust"; 115="first baptist church jonesboro"; 190="first church"; 20="first missouri state bank of cape county"; 133="first national bank of izard county"; 22="first national bank of lawrence county"; 83="first state bank and trust"; 88="five rivers medical center"; 122="fm bank"; 130="first missouri state bank of poplar bluff"; 171="gammel's clinic pharmacy"; 148="gateway bank"; 178="greenlab"; 106="ground crew"; 44="halsey thrasher harpole"; 157="hammerhead contracting and development"; 176="hawthorn river"; 166="hc3"; 184="healthy connections"; 162="hilltop eye care"; 170="icare rx"; 104="jester law firm"; 34="johnston and mccoy"; 110="jonesboro regional chamber of commerce"; 118="jonesboro roofing company"; 1="kalmer solutions"; 151="kion pediatric clinic"; 164="lawrence and lawrence"; 161="laws flooring and ruge"; 47="loggins logistics"; 165="may security systems"; 105="mc express"; 188="mcdaniel alw firm"; 48="md thompson and sons"; 175="meadows contractors"; 84="medic one"; 135="mid south steel"; 112="mid river terminal"; 182="mor media incorporated"; 134="nathan's installs"; 150="orthopedic and spine surgery center"; 26="peoples bank"; 27="piggott state bank"; 149="precision digital printing"; 120="pregnancy resource center"; 36="Premiere tans"; 191="prestige tax advisors"; 113="professional titel services"; 160="r and g masonry"; 132="red wolves foundation"; 6="riverwind bank"; 136="row and row smile studio"; 89="sage meadows"; 125="saints avenue bank"; 187="sarc travis d. richardson"; 193="schuber mitchell homes"; 42="scurlock industries"; 28="security bank"; 114="senath state bank"; 144="service abstract"; 179="shinabery's compounding pharmacy"; 185="skin dermatology"; 167="snider performance spine"; 180="southeast missouri title company"; 117="stone bank"; 59="sunbelt finance"; 147="tec electric"; 90="tier inv"; 85="town and country bank"; 174="trumann mayor's office"; 152="union bankshares"; 183="united way of nea"; 116="visionary eye care"; 189="welch couch and company cpa"; 40="widner penter cpa"; 41="windmill rice"}
    For ($i=0,$i -lt $DataSource[0].length; $i++) {
        if ($Term -like $DataSource[$i].Value ) {
            $ResultList.Items.Add($DataSource[$i].Value + " - " + $DataSource[$i].Name)
            Write-Host $Term
        }
    }
    
    
}

# Creating main form and setting attributes
$SearchForm = New-Object System.Windows.Forms.Form
$SearchForm.clientSize = '400,300'
$SearchForm.text = "Company Code Lookup"
$SearchForm.BackColor = "#ffffff"
$SearchForm.FormBorderStyle = 'FixedDialog'

# Creating form elements
$SearchBox = New-Object System.Windows.Forms.TextBox
$SearchBox.Size = '358,240'
$SearchBox.Font = 'Microsoft Sans Serif,24'
$SearchBox.Location = New-Object System.Drawing.Point (20,20)
$ResultList = New-Object System.Windows.Forms.ListBox
$ResultList.Location = New-Object System.Drawing.Point (20,80)
$ResultList.Size = '358,200'


# Adding elements to the form
$SearchForm.Controls.add($SearchBox)
$SearchForm.Controls.add($ResultList)

# Adding Event Trigger
$SearchBox.Add_TextChanged({Get-Results($SearchBox.Text)})

# Display Form
[void]$SearchForm.ShowDialog()
