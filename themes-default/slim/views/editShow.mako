<%inherit file="/layouts/main.mako"/>
<link rel="stylesheet" type="text/css" href="css/vue/editshow.css?${sbPID}" />
<%block name="scripts">
<%include file="/vue-components/select-list-ui.mako"/>
<%include file="/vue-components/anidb-release-group-ui.mako"/>
<script>
window.app = {};
const startVue = () => {
    window.app = new Vue({
        el: '#vue-wrap',
        metaInfo: {
            title: 'Edit Show'
        },
        store,
        data() {
            return {
                seriesSlug: $('#series-slug').attr('value'),
                series: {
                    config: {
                        aliases: [],
                        dvdOrder: null,
                        defaultEpisodeStatus: null,
                        seasonFolders: null,
                        anime: null,
                        scene: null,
                        sports: null,
                        paused: null,
                        location: null,
                        airByDate: null,
                        subtitlesEnabled: null,
                        release: {
                            requiredWords: [],
                            ignoredWords: [],
                            blacklist: [],
                            whitelist: [],
                            allgroups: []
                        },
                        qualities: {
                            preferred: [],
                            allowed: []
                        }
                    },
                    language: 'en'
                },
                showLoaded: false,
                saving: false
            }
        },
        computed: Object.assign(store.mapState(['shows']), {
            params() {
                return location.search.slice(1).split('&').reduce((obj, pair) => {
                    const [ key, value ] = pair.split('=');
                    obj[key] = value;
                    return obj;
                }, {});
            },
            id() {
                return this.params.seriesid;
            },
            indexer() {
                return this.params.indexername;
            },
            // @TODO: Enable this once we remove this.series
            // show() {
            //     const { $store } = this;
            //     return this.shows.length === 0 ? $store.defaults.show : this.shows.find(show => show.indexer === this.indexer && Number(show.id[show.indexer]) === Number(this.id));
            // },
            availableLanguages() {
                if (this.config.indexers.config.main.validLanguages) {
                    return this.config.indexers.config.main.validLanguages.join(',');
                }
            },
            combinedQualities() {
                const reducer = (accumulator, currentValue) => accumulator | currentValue;
                const allowed = this.show.config.qualities.allowed.reduce(reducer, 0);
                const preferred = this.show.config.qualities.preferred.reduce(reducer, 0);

                return (allowed | preferred << 16) >>> 0;  // Unsigned int
            },
            saveButton() {
                return this.saving === false ? 'Save Changes' : 'Saving...';
            },
            displayShowUrl() {
                // @TODO: Change the URL generation to use `this.show`. Currently not possible because
                // the values are not available at the time of app-link component creation.
                return window.location.pathname.replace('editShow', 'displayShow') + window.location.search;
            }
        }),
        mounted() {
            const { $store, indexer, id} = this;

            $store.dispatch('getShow', { indexer, id }).then(() => {
                this.showLoaded = true;
            }).catch(error => {
                console.debug(error);
                console.debug('Could not get show info for: ' + indexer + String(id));
            });
        },
        methods: {
            saveSeries(subject) {
                const { $store } = this;

                // We want to wait until the page has been fully loaded, before starting to save stuff.
                if (!this.showLoaded) {
                    return;
                }

                // Disable the save button until we're done.
                this.saving = true;

                if (['show', 'all'].includes(subject)) {
                    const data = {
                        config: {
                            aliases: this.show.config.aliases,
                            defaultEpisodeStatus: this.show.config.defaultEpisodeStatus,
                            dvdOrder: this.show.config.dvdOrder,
                            seasonFolders: this.show.config.seasonFolders,
                            anime: this.show.config.anime,
                            scene: this.show.config.scene,
                            sports: this.show.config.sports,
                            paused: this.show.config.paused,
                            location: this.show.config.location,
                            airByDate: this.show.config.airByDate,
                            subtitlesEnabled: this.show.config.subtitlesEnabled,
                            release: {
                                requiredWords: this.show.config.release.requiredWords,
                                ignoredWords: this.show.config.release.ignoredWords
                            },
                            qualities: {
                                preferred: this.show.config.qualities.preferred,
                                allowed: this.show.config.qualities.allowed
                            }
                        },
                        language: this.show.language
                    };

                    if (data.config.anime) {
                        data.config.release.blacklist = this.show.config.release.blacklist;
                        data.config.release.whitelist = this.show.config.release.whitelist;
                    }

                    const { indexer, id } = this;
                    $store.dispatch('setShow', { indexer, id, data, save: true }).then(() => {
                        this.$snotify.success('You may need to "Re-scan files" or "Force Full Update".', 'Saved', { timeout: 5000 });
                    }).catch(error => {
                        this.$snotify.error(
                            'Error while trying to save "' + this.show.title + '": ' + error.message || 'Unknown',
                            'Error'
                        );
                    });
                }

                // Re-enable the save button.
                this.saving = false;
            },
            onChangeIgnoredWords(items) {
                this.show.config.release.ignoredWords = items.map(item => item.value);
            },
            onChangeRequiredWords(items) {
                this.show.config.release.requiredWords = items.map(item => item.value);
            },
            onChangeAliases(items) {
                this.show.config.aliases = items.map(item => item.value);
            },
            onChangeReleaseGroupsAnime(items) {
                this.show.config.release.whitelist = items.filter(item => item.memberOf === 'whitelist');
                this.show.config.release.blacklist = items.filter(item => item.memberOf === 'blacklist');
                this.show.config.release.allgroups = items.filter(item => item.memberOf === 'releasegroups');
            },
            updateLanguage(value) {
                this.show.language = value;
            }
        }
    });
};
</script>
</%block>
<%block name="content">
<vue-snotify></vue-snotify>
<input type="hidden" id="indexer-name" value="${show.indexer_name}" />
<input type="hidden" id="series-id" value="${show.indexerid}" />
<input type="hidden" id="series-slug" value="${show.slug}" />
<h1 class="header">
    Edit Show
    <span v-show="show.title"> - <app-link :href="displayShowUrl">{{show.title}}</app-link></span>
</h1>
<div id="config-content">
    <div id="config" :class="{ summaryFanArt: config.fanartBackground }">
        <form @submit.prevent="saveSeries('all')" class="form-horizontal">
            <div id="config-components">
                <ul>
                    <li><app-link href="#core-component-group1">Main</app-link></li>
                    <li><app-link href="#core-component-group2">Format</app-link></li>
                    <li><app-link href="#core-component-group3">Advanced</app-link></li>
                </ul>
                <div id="core-component-group1">
                    <div class="component-group">
                        <h3>Main Settings</h3>
                        <fieldset class="component-group-list">
                            <div class="form-group">
                                <label for="location" class="col-sm-2 control-label">Show Location</label>
                                <div class="col-sm-10 content">
                                    <input type="hidden" name="indexername" id="form-indexername" :value="indexer"/>
                                    <input type="hidden" name="seriesid" id="form-seriesid" :value="id" />
                                    <file-browser name="location" title="Select Show Location" :initial-dir="show.config.location" @update="show.config.location = $event"></file-browser>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="qualityPreset" class="col-sm-2 control-label">Preferred Quality</label>
                                <div class="col-sm-10 content">
                                    <quality-chooser :overall-quality="combinedQualities" @update:quality:allowed="show.config.qualities.allowed = $event" @update:quality:preferred="show.config.qualities.preferred = $event"></quality-chooser>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="defaultEpStatusSelect" class="col-sm-2 control-label">Default Episode Status</label>
                                <div class="col-sm-10 content">
                                    <select v-model="show.config.defaultEpisodeStatus" name="defaultEpStatus" id="defaultEpStatusSelect" class="form-control form-control-inline input-sm"/>
                                        <option value="Wanted">Wanted</option>
                                        <option value="Skipped">Skipped</option>
                                        <option value="Ignored">Ignored</option>
                                    </select>
                                    <div class="clear-left"><p>This will set the status for future episodes.</p></div>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="indexerLangSelect" class="col-sm-2 control-label">Info Language</label>
                                <div class="col-sm-10 content">
                                    <language-select id="indexerLangSelect" @update-language="updateLanguage" :language="show.language" :available="availableLanguages" name="indexer_lang" id="indexerLangSelect" class="form-control form-control-inline input-sm"></language-select>
                                    <div class="clear-left"><p>This only applies to episode filenames and the contents of metadata files.</p></div>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="subtitles" class="col-sm-2 control-label">Subtitles</label>
                                <div class="col-sm-10 content">
                                    <toggle-button :width="45" :height="22" id="subtitles" name="subtitles" v-model="show.config.subtitlesEnabled" sync></toggle-button>
                                    <span>search for subtitles</span>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="paused" class="col-sm-2 control-label">Paused</label>
                                <div class="col-sm-10 content">
                                    <toggle-button :width="45" :height="22" id="paused" name="paused" v-model="show.config.paused" sync></toggle-button>
                                    <span>pause this show (Medusa will not download episodes)</span>
                                </div>
                            </div>
                        </fieldset>
                    </div>
                </div>
                <div id="core-component-group2">
                    <div class="component-group">
                        <h3>Format Settings</h3>
                        <fieldset class="component-group-list">
                            <div class="form-group">
                                <label for="airbydate" class="col-sm-2 control-label">Air by date</label>
                                <div class="col-sm-10 content">
                                    <toggle-button :width="45" :height="22" id="airbydate" name="air_by_date" v-model="show.config.airByDate" sync></toggle-button>
                                    <span>check if the show is released as Show.03.02.2010 rather than Show.S02E03</span>
                                    <p style="color:rgb(255, 0, 0);">In case of an air date conflict between regular and special episodes, the later will be ignored.</p>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="anime" class="col-sm-2 control-label">Anime</label>
                                <div class="col-sm-10 content">
                                    <toggle-button :width="45" :height="22" id="anime" name="anime" v-model="show.config.anime" sync></toggle-button>
                                    <span>enable if the show is Anime and episodes are released as Show.265 rather than Show.S02E03</span>
                                </div>
                            </div>

                            <div v-if="show.config.anime" class="form-group">
                                <label for="anidbReleaseGroup" class="col-sm-2 control-label">Release Groups</label>
                                <div class="col-sm-10 content">
                                    <anidb-release-group-ui class="max-width" :blacklist="show.config.release.blacklist" :whitelist="show.config.release.whitelist" :all-groups="show.config.release.allgroups" @change="onChangeReleaseGroupsAnime"></anidb-release-group-ui>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="sports" class="col-sm-2 control-label">Sports</label>
                                <div class="col-sm-10 content">
                                    <toggle-button :width="45" :height="22" id="sports" name="sports" v-model="show.config.sports" sync></toggle-button>
                                    <span>enable if the show is a sporting or MMA event released as Show.03.02.2010 rather than Show.S02E03<span>
                                    <p style="color:rgb(255, 0, 0);">In case of an air date conflict between regular and special episodes, the later will be ignored.</p>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="season_folders" class="col-sm-2 control-label">Season folders</label>
                                <div class="col-sm-10 content">
                                    <toggle-button :width="45" :height="22" id="season_folders" name="season_folders" v-model="show.config.seasonFolders" sync></toggle-button>
                                    <span>group episodes by season folder (disable to store in a single folder)</span>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="scene" class="col-sm-2 control-label">Scene Numbering</label>
                                <div class="col-sm-10 content">
                                    <toggle-button :width="45" :height="22" id="scene" name="scene" v-model="show.config.scene" sync></toggle-button>
                                    <span>search by scene numbering (disable to search by indexer numbering)</span>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="dvdorder" class="col-sm-2 control-label">DVD Order</label>
                                <div class="col-sm-10 content">
                                    <toggle-button :width="45" :height="22" id="dvdorder" name="dvdorder" v-model="show.config.dvdOrder" sync></toggle-button>
                                    <span>use the DVD order instead of the air order</span>
                                    <div class="clear-left"><p>A "Force Full Update" is necessary, and if you have existing episodes you need to sort them manually.</p></div>
                                </div>
                            </div>
                        </fieldset>
                    </div>
                </div>
                <div id="core-component-group3">
                    <div class="component-group">
                        <h3>Advanced Settings</h3>
                        <fieldset class="component-group-list">

                            <div class="form-group">
                                <label for="rls_ignore_words" class="col-sm-2 control-label">Ignored words</label>
                                <div class="col-sm-10 content">
                                    <select-list :list-items="show.config.release.ignoredWords" @change="onChangeIgnoredWords"></select-list>
                                    <div class="clear-left">
                                        <p>Search results with one or more words from this list will be ignored.</p>
                                    </div>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="rls_require_words" class="col-sm-2 control-label">Required words</label>
                                <div class="col-sm-10 content">
                                    <select-list :list-items="show.config.release.requiredWords" @change="onChangeRequiredWords"></select-list>
                                    <div class="clear-left">
                                        <p>Search results with no words from this list will be ignored.</p>
                                    </div>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="SceneName" class="col-sm-2 control-label">Scene Exception</label>
                                <div class="col-sm-10 content">
                                    <select-list :list-items="show.config.aliases" @change="onChangeAliases"></select-list>
                                    <div class="clear-left">
                                        <p>This will affect episode search on NZB and torrent providers. This list appends to the original show name.</p>
                                    </div>
                                </div>
                            </div>

                        </fieldset>
                    </div>
                </div>
            </div>
            <br>
            <input id="submit" type="submit" :value="saveButton" class="btn-medusa pull-left button" :disabled="saving || !showLoaded">
        </form>
    </div>
</div>
</%block>
