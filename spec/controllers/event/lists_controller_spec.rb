# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

require 'spec_helper'

describe Event::ListsController do
  include ActiveSupport::Testing::TimeHelpers

  before do
    travel_to(Time.local(2015, 07, 15))
    sign_in(user)
  end

  after   { travel_back }
  subject { assigns(:camps).values.flatten }

  describe 'GET all_camps' do

    context 'as bulei' do
      let(:user) { people(:bulei) }

      before do
        now = Time.zone.now
        @current = fabricate_pbs_camp(groups: [groups(:schekka)], camp_submitted: true, state: 'closed')
        @current.dates = [Fabricate(:event_date, start_at: now - 15.days, finish_at: now - 10.days),
                          Fabricate(:event_date, start_at: now - 5.days, finish_at: now + 5.days)]
        @upcoming = fabricate_pbs_camp(groups: [groups(:zh)], camp_submitted: true, state: 'confirmed')
        @upcoming.dates = [Fabricate(:event_date, start_at: now + 10.days, finish_at: nil),
                           Fabricate(:event_date, start_at: now + 12.days, finish_at: nil)]
        @upcoming2 = fabricate_pbs_camp(groups: [groups(:zh)], camp_submitted: true, state: 'created')
        @upcoming2.dates = [Fabricate(:event_date, start_at: now + 18.days, finish_at: now + 30.days),
                            Fabricate(:event_date, start_at: now + 50.days, finish_at: now + 55.days)]
        past = fabricate_pbs_camp(groups: [groups(:zh)], camp_submitted: true, state: 'confirmed')
        past.dates = [Fabricate(:event_date, start_at: now - 5.days, finish_at: nil)]
        canceled = fabricate_pbs_camp(groups: [groups(:zh)], camp_submitted: true, state: 'canceled')
        canceled.dates = [Fabricate(:event_date, start_at: now + 5.days, finish_at: nil)]
        unsubmitted = fabricate_pbs_camp(groups: [groups(:zh)], camp_submitted: false, state: 'confirmed')
        unsubmitted.dates = [Fabricate(:event_date, start_at: now + 5.days, finish_at: nil)]
        future = fabricate_pbs_camp(groups: [groups(:zh)], camp_submitted: true, state: 'confirmed')
        future.dates = [Fabricate(:event_date, start_at: now + 50.days, finish_at: nil)]
      end

      it 'contains only current and upcoming camps' do
        get :all_camps
        is_expected.to eq([@current, @upcoming, @upcoming2])
      end

      it 'via list_camps' do
        expect(get :camps).to redirect_to(list_all_camps_path)
      end
    end

    context 'as abteilungsleitung' do
      let(:user) { people(:al_schekka) }

      it 'is not allowed' do
        expect { get :all_camps }.to raise_error(CanCan::AccessDenied)
      end

      it 'is not allowed via list_camp' do
        expect { get :camps }.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe 'GET kantonalverband_camps' do

    context 'as kantonsleitung' do
      let(:user) { Fabricate(Group::Kantonalverband::Kantonsleitung.name, group: groups(:be)).person }

      before do
        now = Time.zone.now
        @current = fabricate_pbs_camp(groups: [groups(:schekka)], camp_submitted: true, state: 'closed')
        @current.dates = [Fabricate(:event_date, start_at: now - 15.days, finish_at: now - 10.days),
                          Fabricate(:event_date, start_at: now - 5.days, finish_at: now + 5.days)]
        @early = fabricate_pbs_camp(groups: [groups(:be)], camp_submitted: true, state: 'confirmed')
        @early.dates = [Fabricate(:event_date, start_at: Date.new(now.year, 3, 1), finish_at: Date.new(now.year, 3, 10))]
        @late = fabricate_pbs_camp(groups: [groups(:bern)], camp_submitted: true, state: 'confirmed')
        @late.dates = [Fabricate(:event_date, start_at: Date.new(now.year, 12, 1))]
        created = fabricate_pbs_camp(groups: [groups(:schekka)], camp_submitted: true, state: 'created')
        created.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
        canceled = fabricate_pbs_camp(groups: [groups(:schekka)], camp_submitted: true, state: 'canceled')
        canceled.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
        unsubmitted = fabricate_pbs_camp(groups: [groups(:schekka)], camp_submitted: false, state: 'confirmed')
        unsubmitted.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
        future = fabricate_pbs_camp(groups: [groups(:be)], camp_submitted: true, state: 'confirmed')
        future.dates = [Fabricate(:event_date, start_at: now + 1.year, finish_at: nil)]
        other = fabricate_pbs_camp(groups: [groups(:zh)], camp_submitted: true, state: 'confirmed')
        other.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
      end

      it 'contains all camps in all subgroups this year' do
        get :kantonalverband_camps, group_id: groups(:be).id
        is_expected.to match_array([@current, @early, @late])
      end

      it 'via list_camps' do
        expect(get :camps).to redirect_to(list_kantonalverband_camps_path(group_id: groups(:be).id))
      end
    end

    context 'as bulei' do
      let(:user) { people(:bulei) }

      it 'is not allowed' do
        expect { get :kantonalverband_camps, group_id: groups(:be).id }.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe 'GET camps_in_canton' do

    context 'as krisenverantwortung' do
      let(:user) { Fabricate(Group::Kantonalverband::VerantwortungKrisenteam.name, group: groups(:be)).person }

      before do
        now = Time.zone.now
        groups(:be).update!(cantons: %w(be fr))

        @current = fabricate_pbs_camp(groups: [groups(:schekka)], camp_submitted: true, state: 'closed', canton: 'be')
        @current.dates = [Fabricate(:event_date, start_at: now - 15.days, finish_at: now - 10.days),
                          Fabricate(:event_date, start_at: now - 5.days, finish_at: now + 5.days)]
        @upcoming = fabricate_pbs_camp(groups: [groups(:chaeib)], camp_submitted: true, state: 'confirmed', canton: 'be')
        @upcoming.dates = [Fabricate(:event_date, start_at: now + 18.days, finish_at: now + 30.days),
                           Fabricate(:event_date, start_at: now + 50.days, finish_at: now + 55.days)]
        created = fabricate_pbs_camp(groups: [groups(:schekka)], camp_submitted: true, state: 'created', canton: 'be')
        created.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
        canceled = fabricate_pbs_camp(groups: [groups(:schekka)], camp_submitted: true, state: 'canceled', canton: 'be')
        canceled.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
        unsubmitted = fabricate_pbs_camp(groups: [groups(:schekka)], camp_submitted: false, state: 'confirmed', canton: 'be')
        unsubmitted.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
        future = fabricate_pbs_camp(groups: [groups(:be)], camp_submitted: true, state: 'confirmed', canton: 'be')
        future.dates = [Fabricate(:event_date, start_at: now + 1.year, finish_at: nil)]
        other = fabricate_pbs_camp(groups: [groups(:zh)], camp_submitted: true, state: 'confirmed', canton: 'zh')
        other.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
      end

      it 'contains all upcoming camps in this canton' do
        get :camps_in_canton, canton: 'be'
        is_expected.to match_array([@current, @upcoming])
      end

      it 'via list_camps' do
        expect(get :camps).to redirect_to(list_kantonalverband_camps_path(group_id: groups(:be).id))
      end
    end

  end

  describe 'GET camps_abroad' do
    context 'as ko int' do
      let(:user) { Fabricate(Group::Bund::InternationalCommissionerIcWagggs.name, group: groups(:bund)).person }

      before do
        now = Time.zone.now
        @current = fabricate_pbs_camp(groups: [groups(:schekka)], camp_submitted: true, state: 'closed', canton: 'zz')
        @current.dates = [Fabricate(:event_date, start_at: now - 15.days, finish_at: now - 10.days),
                          Fabricate(:event_date, start_at: now - 5.days, finish_at: now + 5.days)]
        @early = fabricate_pbs_camp(groups: [groups(:be)], camp_submitted: true, state: 'confirmed', canton: 'zz')
        @early.dates = [Fabricate(:event_date, start_at: Date.new(now.year, 3, 1), finish_at: Date.new(now.year, 3, 10))]
        created = fabricate_pbs_camp(groups: [groups(:schekka)], camp_submitted: true, state: 'created', canton: 'zz')
        created.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
        canceled = fabricate_pbs_camp(groups: [groups(:schekka)], camp_submitted: true, state: 'canceled', canton: 'zz')
        canceled.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
        unsubmitted = fabricate_pbs_camp(groups: [groups(:schekka)], camp_submitted: false, state: 'confirmed', canton: 'zz')
        unsubmitted.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
        future = fabricate_pbs_camp(groups: [groups(:be)], camp_submitted: true, state: 'confirmed', canton: 'zz')
        future.dates = [Fabricate(:event_date, start_at: now + 1.year, finish_at: nil)]
        other = fabricate_pbs_camp(groups: [groups(:zh)], camp_submitted: true, state: 'confirmed', canton: 'be')
        other.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
        empty = fabricate_pbs_camp(groups: [groups(:zh)], camp_submitted: true, state: 'confirmed')
        empty.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
      end

      it 'contains all abroad camps this year' do
        get :camps_abroad
        is_expected.to match_array([@current, @early])
      end

      it 'via list_camps' do
        expect(get :camps).to redirect_to(list_camps_abroad_path)
      end
    end
  end

  describe 'GET #bsv_export' do
    let(:rows) { response.body.split("\r\n") }
    let(:user) { people(:bulei) }
    let(:kind) { event_kinds(:fut) }
    let(:person) do
      Fabricate(:person, address: 'test_address',
                         zip_code: '3128',
                         town: 'Foodorf',
                         country: 'CH')
    end

    before do
      create_course('124', '11.11.2015', '12.11.2015')
      create_course('124', '11.11.2015')
    end

    context 'advanced' do
      it 'includes advanced attribute labels' do
        get :bsv_export, bsv_export: { event_kinds: [kind.id], date_from: '09.09.2015' },
          year: 2016, advanced: true

        labels = rows.first.split(';')
        expect(labels).to eq(["Vereinbarung-ID-FiVer",
                              "Kurs-ID-FiVer",
                              "Kursart",
                              "Kantonalverband",
                              "Regionalverband",
                              "Kursnummer",
                              "Start Datum",
                              "End Datum",
                              "Kursort",
                              "Personen-ID",
                              "Vorname",
                              "Nachname",
                              "Pfadiname",
                              "Adresse",
                              "PLZ",
                              "Ort",
                              "Land",
                              "Email",
                              "Anrede"])
      end

      it 'inserts values correctly' do
        get :bsv_export, bsv_export: { date_from: '09.09.2015' },
          year: 2016, advanced: true

        values = rows.second.split(';')
        expect(values).to eq(["", "", "LPK (Leitpfadikurs)", "Zürich, Bern",
                              '""', "124", "11.11.2015", "12.11.2015", "",
                              person.id.to_s, person.first_name, person.last_name,
                              person.nickname, "test_address", "3128", "Foodorf", "CH",
                              person.email, person.salutation_value])
      end

      it 'sets date_to to date from if nothing is given' do
        get :bsv_export, bsv_export: { date_from: '09.09.2015' },
          year: 2016, advanced: true

        values = rows.third.split(';')
        expect(values[6]).to eq('11.11.2015')
        expect(values[7]).to eq('11.11.2015')
      end
    end

    context 'access via api' do
      before do
        sign_out(user)
      end

      it 'responses csv' do
        user.generate_authentication_token!

        get :bsv_export, bsv_export: { date_from: '09.09.2015' }, year: 2016,
          advanced: true, user_token: user.authentication_token, user_email: user.email

        expect(rows.length).to eq(3)
      end
    end
  end


  def fabricate_pbs_camp(overrides={})
    if overrides[:camp_submitted]
      overrides = required_attrs_for_camp_submit.
        merge(overrides)
    end
    Fabricate(:pbs_camp, overrides)
  end

  def required_attrs_for_camp_submit
    { canton: 'be',
      location: 'foo',
      coordinates: '42',
      altitude: '1001',
      emergency_phone: '080011',
      landlord: 'georg',
      coach_confirmed: true,
      lagerreglement_applied: true,
      kantonalverband_rules_applied: true,
      j_s_rules_applied: true,
      expected_participants_pio_f: 3,
      coach_id: Fabricate(:person).id,
      leader_id: Fabricate(:person).id
    }
  end

  def create_course(number, date_from, date_to = nil)
    course = Fabricate(:pbs_course, groups: [groups(:be), groups(:zh)], number: number, state: 'closed', advisor_id: person.id)
    course.dates.destroy_all
    date_from = Date.parse(date_from)
    date_to = Date.parse(date_to) if date_to
    course.dates.create!(start_at: date_from, finish_at: date_to)
  end

end
