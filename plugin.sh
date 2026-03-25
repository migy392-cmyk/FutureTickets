#!/bin/bash
# ============================================
# Instalador Plugin Ticket Futuro para GLPI 11 # Ejecutar como root o con sudo
# Uso: bash install_ticketfuturo.sh /ruta/a/glpi # ============================================

GLPI_PATH="${1:-/var/www/glpi}" PLUGIN_DIR="$GLPI_PATH/plugins/ticketfuturo"

echo "==> Instalando plugin Ticket Futuro en: $PLUGIN_DIR"

mkdir -p "$PLUGIN_DIR/inc" mkdir -p "$PLUGIN_DIR/front" mkdir -p "$PLUGIN_DIR/locales"
mkdir -p "$PLUGIN_DIR/templates"

# ---- setup.php ----
cat > "$PLUGIN_DIR/setup.php" << 'EoF'
<?php
define('PLUGIN_TICKETFUTURo_VERSIoN', '1.0.2');
define('PLUGIN_TICKETFUTURo_MIN_GLPI', '11.0.0');
define('PLUGIN_TICKETFUTURo_MAX_GLPI', '11.99.99');

function plugin_init_ticketfuturo() { global $PLUGIN_HooKS;
$PLUGIN_HooKS['csrf_compliant']['ticketfuturo'] = true; Plugin::registerClass('PluginTicketfuturoScheduledTicket'); Plugin::registerClass('PluginTicketfuturoProfile');
if (Session::haveRight('plugin_ticketfuturo', READ)) {
$PLUGIN_HooKS['menu_toadd']['ticketfuturo'] = [ 'admin' => 'PluginTicketfuturoScheduledTicket',
];
}
}

function plugin_version_ticketfuturo() { return [
'name'	=> 'Ticket Futuro',
'version'	=> PLUGIN_TICKETFUTURo_VERSIoN,
'author'	=> 'GLPI Plugin',
'license'	=> 'GPL v2+',
'homepage'	=> '', 'requirements' => [
 
'glpi' => [
'min' => PLUGIN_TICKETFUTURo_MIN_GLPI, 'max' => PLUGIN_TICKETFUTURo_MAX_GLPI,
],
'php' => ['min' => '8.1'],
],
];
}

function plugin_ticketfuturo_check_prerequisites() { if (!defined('GLPI_VERSIoN')) return false;
if (version_compare(GLPI_VERSIoN, PLUGIN_TICKETFUTURo_MIN_GLPI, 'lt')) { echo 'Requiere GLPI >= ' . PLUGIN_TICKETFUTURo_MIN_GLPI;
return false;
}
return true;
}

function plugin_ticketfuturo_check_config() { return true;
}
EoF

# ---- hook.php ----
cat > "$PLUGIN_DIR/hook.php" << 'EoF'
<?php
function plugin_ticketfuturo_install() { global $DB;
$migration = new Migration(PLUGIN_TICKETFUTURo_VERSIoN);
if (!$DB->tableExists('glpi_plugin_ticketfuturo_scheduledtickets')) {
$migration->addField('glpi_plugin_ticketfuturo_scheduledtickets', 'id', '
$migration->addField('glpi_plugin_ticketfuturo_scheduledtickets', 'name',
$migration->addField('glpi_plugin_ticketfuturo_scheduledtickets', 'conten
$migration->addField('glpi_plugin_ticketfuturo_scheduledtickets', 'schedu
$migration->addField('glpi_plugin_ticketfuturo_scheduledtickets', 'status
$migration->addField('glpi_plugin_ticketfuturo_scheduledtickets', 'ticket
$migration->addField('glpi_plugin_ticketfuturo_scheduledtickets', 'type',
$migration->addField('glpi_plugin_ticketfuturo_scheduledtickets', 'itilca
$migration->addField('glpi_plugin_ticketfuturo_scheduledtickets', 'users_
$migration->addField('glpi_plugin_ticketfuturo_scheduledtickets', 'groups
$migration->addField('glpi_plugin_ticketfuturo_scheduledtickets', 'users_
$migration->addField('glpi_plugin_ticketfuturo_scheduledtickets', 'priori
$migration->addField('glpi_plugin_ticketfuturo_scheduledtickets', 'entiti
$migration->addField('glpi_plugin_ticketfuturo_scheduledtickets', 'users_
$migration->addField('glpi_plugin_ticketfuturo_scheduledtickets', 'date_c
$migration->addField('glpi_plugin_ticketfuturo_scheduledtickets', 'date_m
$migration->addKey('glpi_plugin_ticketfuturo_scheduledtickets', 'schedule
 
$migration->addKey('glpi_plugin_ticketfuturo_scheduledtickets', 'status')
$migration->addKey('glpi_plugin_ticketfuturo_scheduledtickets', 'entities
$migration->executeMigration();
}
include_once(GLPI_RooT . '/plugins/ticketfuturo/inc/profile.class.php'); PluginTicketfuturoProfile::initProfile();
if (isset($_SESSIoN['glpiactiveprofile']['id'])) { PluginTicketfuturoProfile::createFirstAccess($_SESSIoN['glpiactiveprofile
}
CronTask::register( 'PluginTicketfuturoScheduledTicket', 'CreateScheduledTickets', HoUR_TIMESTAMP,
['comment' => 'Crear tickets futuros programados automáticamente', 'mode'
);
return true;
}

function plugin_ticketfuturo_uninstall() {
$migration = new Migration(PLUGIN_TICKETFUTURo_VERSIoN);
$migration->dropTable('glpi_plugin_ticketfuturo_scheduledtickets');
$migration->executeMigration();
$profileRight = new ProfileRight();
$profileRight->deleteByCriteria(['name' => 'plugin_ticketfuturo']);
$cron = new CronTask();
$cron->deleteByCriteria(['itemtype' => 'PluginTicketfuturoScheduledTicket']); return true;
}
EoF

# ---- inc/profile.class.php ----
cat > "$PLUGIN_DIR/inc/profile.class.php" << 'EoF'
<?php
if (!defined('GLPI_RooT')) die("No direct access");

class PluginTicketfuturoProfile extends CommonDBTM { static $rightname = 'profile';

public static function initProfile() {
if (!countElementsInTable('glpi_profilerights', ['name' => 'plugin_ticket ProfileRight::addProfileRights(['plugin_ticketfuturo']);
}
}

public static function createFirstAccess($profiles_id) { if (!$profiles_id) return;
if (countElementsInTable('glpi_profilerights', ['profiles_id' => $profile
 
$profileRight = new ProfileRight();
$profileRight->add([
'profiles_id' => $profiles_id,
'name'	=> 'plugin_ticketfuturo',
'rights'	=> READ | UPDATE | CREATE | DELETE | PURGE,
]);
}
}
EoF

# ---- inc/scheduledticket.class.php ----
cat > "$PLUGIN_DIR/inc/scheduledticket.class.php" << 'EoF'
<?php
if (!defined('GLPI_RooT')) die("No direct access");

class PluginTicketfuturoScheduledTicket extends CommonDBTM { static $rightname = 'plugin_ticketfuturo';

public static function getTypeName($nb = 0) { return 'Ticket Futuro'; } public static function getMenuName() { return 'Tickets Futuros'; }

public static function getMenuContent() {
$menu = [];
if (self::canView()) {
$menu['title'] = self::getMenuName();
$menu['page'] = '/plugins/ticketfuturo/front/scheduledticket.php';
$menu['icon'] = 'ti ti-clock-plus';
$menu['options']['scheduledticket']['title']	= self::getMen
$menu['options']['scheduledticket']['page']	= '/plugins/ti
$menu['options']['scheduledticket']['links']['search'] = '/plugins/ti if (self::canCreate()) {
$menu['options']['scheduledticket']['links']['add'] = '/plugins/t
}
}
return $menu;
}

public function defineTabs($options = []) {
$ong = [];
$this->addDefaultFormTab($ong); return $ong;
}

public function rawSearchoptions() {
$tab = [];
$tab[] = ['id' => 'common', 'name' => self::getTypeName(1)];
$tab[] = ['id' => '1', 'table' => $this->getTable(), 'field' => 'name',
 
$tab[] = ['id' => '2', 'table' => $this->getTable(), 'field' => 'schedule
$tab[] = ['id' => '3', 'table' => $this->getTable(), 'field' => 'status',
$tab[] = ['id' => '4', 'table' => $this->getTable(), 'field' => 'priority
$tab[] = ['id' => '5', 'table' => 'glpi_itilcategories', 'field' => 'comp
$tab[] = ['id' => '6', 'table' => $this->getTable(), 'field' => 'type', return $tab;
}

public function showForm($ID, $options = []) {
$this->initForm($ID, $options);
TemplateRenderer::getInstance()->display('@ticketfuturo/scheduledticket.f 'item'	=> $this,
'params' => $options,
]);
return true;
}

public function prepareInputForAdd($input) {
$input['date_creation']	= date('Y-m-d H:i:s');
$input['date_mod']	= date('Y-m-d H:i:s');
$input['users_id_creator'] = Session::getLoginUserID();
$input['entities_id']	= $input['entities_id'] ?? $_SESSIoN['glpiacti
$input['status']	= 0;
if (empty($input['scheduled_date'])) { Session::addMessageAfterRedirect('La fecha programada es obligatoria. return false;
}
if (strtotime($input['scheduled_date']) <= time()) { Session::addMessageAfterRedirect('La fecha programada debe ser futura return false;
}
return $input;
}

public function prepareInputForUpdate($input) {
$input['date_mod'] = date('Y-m-d H:i:s'); return $input;
}

public function cancelScheduledTicket($id) {
return $this->update(['id' => $id, 'status' => 2, 'date_mod' => date('Y-m
}

public static function cronCreateScheduledTickets($task) { global $DB;
$now = date('Y-m-d H:i:s');
$created = 0; $errors = 0;
 
$iterator = $DB->request([
'FRoM' => 'glpi_plugin_ticketfuturo_scheduledtickets', 'WHERE' => ['status' => 0, 'scheduled_date' => ['<=', $now]],
]);
foreach ($iterator as $row) {
$ticket	= new Ticket();
$ticket_id = $ticket->add([
'name'	=> $row['name'],
'content'	=> $row['content'],
'type'	=> $row['type'], 'itilcategories_id'	=> $row['itilcategories_id'], 'priority'	=> $row['priority'], 'entities_id'	=> $row['entities_id'], '_users_id_assign'	=> $row['users_id_assign'], '_groups_id_assign'	=> $row['groups_id_assign'],
'_users_id_requester' => $row['users_id_requester'] ?: 0, 'status'	=> Ticket::INCoMING,
]);
$scheduled = new self(); if ($ticket_id) {
$scheduled->update(['id' => $row['id'], 'status' => 1, 'tickets_i self::sendCreationNotification($row, $ticket_id);
$created++;
$task->addVolume(1);
$task->log("Ticket futuro ID {$row['id']} creado como Ticket #{$t
} else {
$errors++;
$task->log("Error al crear ticket futuro ID {$row['id']}");
}
}
return ($errors > 0) ? -1 : ($created > 0 ? 1 : 0);
}

public static function cronInfo($name) {
return ['description' => 'Crear tickets programados cuando llegue su fech
}

protected static function sendCreationNotification($scheduledData, $ticket_id
$user = new User();
if (!$user->getFromDB($scheduledData['users_id_creator'])) return;
$email = $user->getDefaultEmail(); if (empty($email)) return;
$mmail = new GLPIMailer();
$mmail->AddAddress($email, $user->getFriendlyName());
$mmail->SetFrom(defined('GLPI_NoREPLY_EMAIL') ? GLPI_NoREPLY_EMAIL : 'nor
$mmail->Subject = "[GLPI] Ticket Futuro creado: {$scheduledData['name']}
$mmail->Body	= "El ticket futuro '{$scheduledData['name']}' ha sido cr
 



}
}
EoF
 
$mmail->IsHTML(false);
$mmail->Send();
 

# ---- front/scheduledticket.php ----
cat > "$PLUGIN_DIR/front/scheduledticket.php" << 'EoF'
<?php include('../../../inc/includes.php');
Session::checkRight('plugin_ticketfuturo', READ);
Html::header('Tickets Futuros', $_SERVER['PHP_SELF'], 'admin', 'PluginTicketfutur Search::show('PluginTicketfuturoScheduledTicket');
Html::footer();
EoF

# ---- front/scheduledticket.form.php ----
cat > "$PLUGIN_DIR/front/scheduledticket.form.php" << 'EoF'
<?php include('../../../inc/includes.php');
Session::checkRight('plugin_ticketfuturo', READ);
$item = new PluginTicketfuturoScheduledTicket(); if (isset($_PoST['add'])) {
Session::checkRight('plugin_ticketfuturo', CREATE);
$item->check(-1, CREATE, $_PoST);
$item->add($_PoST);
Html::back();
} elseif (isset($_PoST['update'])) { Session::checkRight('plugin_ticketfuturo', UPDATE);
$item->check($_PoST['id'], UPDATE, $_PoST);
$item->update($_PoST); Html::back();
} elseif (isset($_PoST['delete'])) { Session::checkRight('plugin_ticketfuturo', DELETE);
$item->check($_PoST['id'], DELETE, $_PoST);
$item->delete($_PoST);
Html::redirect(Plugin::getWebDir('ticketfuturo') . '/front/scheduledticket.ph
} elseif (isset($_PoST['cancel'])) { Session::checkRight('plugin_ticketfuturo', UPDATE);
$item->getFromDB($_PoST['id']);
if ($item->fields['status'] == 0) {
$item->cancelScheduledTicket($_PoST['id']); Session::addMessageAfterRedirect('Ticket futuro cancelado correctamente.'
}
Html::back();
} else {
$ID = $_GET['id'] ?? -1;
 




}
EoF
 
Html::header('Ticket Futuro', $_SERVER['PHP_SELF'], 'admin', 'PluginTicketfut
$item->display(['id' => $ID]); Html::footer();
 

# ---- templates/scheduledticket.form.html.twig ----
cat > "$PLUGIN_DIR/templates/scheduledticket.form.html.twig" << 'EoF'
{% extends "generic_show_form.html.twig" %}
{% import 'components/form/fields_macros.html.twig' as fields %}

{% block form_fields %}

{% if item.fields['status'] == 1 %}
<div class="alert alert-success mb-3">
<i class="ti ti-check me-2"></i>
Este ticket futuro ya fue creado. Ticket generado: #{{ item.fields['t
</div>
{% elseif item.fields['status'] == 2 %}
<div class="alert alert-danger mb-3">
<i class="ti ti-x me-2"></i>
Este ticket futuro fue cancelado.
</div>
{% endif %}

{% set disabled = item.fields['status'] != 0 %}

{{ fields.textField('name', item.fields['name'], 'Titulo', {'full_width': tru
{{ fields.datetimeField('scheduled_date', item.fields['scheduled_date'], 'Fec
{{ fields.dropdownArrayField('type', item.fields['type'], {1: 'Incidencia', 2
{{ fields.dropdownField('ITILCategory', 'itilcategories_id', item.fields['iti
{{ fields.dropdownArrayField('priority', item.fields['priority'], {1: 'Muy ba
{{ fields.dropdownField('User', 'users_id_requester', item.fields['users_id_r
{{ fields.dropdownField('User', 'users_id_assign', item.fields['users_id_assi
{{ fields.dropdownField('Group', 'groups_id_assign', item.fields['groups_id_a
{{ fields.textareaField('content', item.fields['content'], 'Descripcion', {'f

{% if item.fields['id'] > 0 %}
<div class="row mt-3">
<div class="col-md-3">
<label class="form-label fw-bold">Estado</label>
<div>
<span class="badge bg-{{ item.fields['status'] == 0 ? 'warnin
{{ item.fields['status'] == 0 ? 'Pendiente' : (item.field
</span>
</div>
</div>
 
{% if item.fields['status'] == 1 and item.fields['tickets_id'] > 0 %}
<div class="col-md-3">
<label class="form-label fw-bold">Ticket generado</label>
<div>
<a href="{{ path('Ticket.Form') }}?id={{ item.fields['tickets #{{ item.fields['tickets_id'] }}
</a>
</div>
</div>
{% endif %}
</div>
{% endif %}

{% if item.fields['status'] == 0 and item.fields['id'] > 0 %}
<div class="mt-3">
<button type="submit" name="cancel" value="1" class="btn btn-outline-
<i class="ti ti-ban me-1"></i>Cancelar ticket futuro
</button>
</div>
{% endif %}

{% endblock %}
EoF

# ---- Permisos ----
chown -R www-data:www-data "$PLUGIN_DIR" 2>/dev/null || \ chown -R apache:apache "$PLUGIN_DIR" 2>/dev/null || \
echo "AVISo: Ajusta los permisos manualmente con: chown -R www-data:www-data $PLU chmod -R 755 "$PLUGIN_DIR"
echo ""
echo "============================================"
echo " Plugin instalado correctamente en:" echo " $PLUGIN_DIR"
echo "============================================"
echo " Ahora ve a GLPI > Configuracion > Plugins" echo " y activa 'Ticket Futuro'"
echo "============================================"
