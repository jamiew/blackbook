# Development only: the apps that wrote most of the archive, so /apps looks
# like the real thing, and the dev tags handed out among them so every card
# has something to play. Idempotent: apps are found by name, and only tags
# still carrying a test app name are reassigned. Nothing is written to data/.
if Rails.env.development?
  apps = [
    ['Graffiti Analysis', { authors: 'Evan Roth, Chris Sugrue', kind: 'openframeworks',
                            website: 'http://graffitianalysis.com/downloads/',
                            description: 'The original GML capture app: a marker with a light in it, tracked ' \
                                         'by a camera. Records tags as GML and uploads them here.' }],
    ['DustTag', { authors: 'Evan Roth, Chris Sugrue', kind: 'other', website: 'http://graffitianalysis.com/iphone/',
                  description: 'Graffiti Analysis for the iPhone. Draw with a finger, upload the GML.' }],
    ['Fat Tag Deluxe', { authors: 'Free Art and Technology Lab, Katsu', kind: 'other',
                         website: 'https://fffff.at/fattag-deluxe-katsu-edition/',
                         description: 'Tag over your own photos on the iPhone, with drips from the accelerometer, ' \
                                      'and upload the GML and a screenshot to 000000book.' }],
    ['EyeWriter', { authors: 'Zach Lieberman, Evan Roth, James Powderly, Theo Watson, Chris Sugrue, Tempt1',
                    kind: 'openframeworks', website: 'http://eyewriter.org',
                    source_url: 'https://github.com/eyewriter/eyewriter',
                    description: 'Low-cost eye tracking that let TEMPT1, paralysed by ALS, draw again. ' \
                                 'His tags are in this archive.' }],
    ['L.A.S.E.R. Tag', { authors: 'Graffiti Research Lab', kind: 'openframeworks',
                         website: 'http://graffitiresearchlab.com/?page_id=76',
                         description: 'A laser pointer, a camera and a projector: tags on the side of a building.' }],
    ['canvasplayer', { authors: 'Jamie Wilkinson', kind: 'javascript', website: 'https://jamiew.github.io/canvasplayer',
                       source_url: 'https://github.com/jamiew/canvasplayer', is_embeddable: true,
                       embed_url: 'https://jamiew.github.io/canvasplayer/',
                       description: 'GML playback on a plain HTML canvas, no dependencies. ' \
                                    'What this site plays with.' }],
    ['Webmarker', { authors: 'Tobias Leingruber, Jamie Wilkinson, Greg Leuch', kind: 'javascript',
                    website: 'http://webmarker.me',
                    description: 'A Firefox add-on for tagging web pages. Captures and plays back GML.' }],
    ['SVG-WOW Graffitis', { authors: 'Vincent Hardy', kind: 'javascript',
                            website: 'http://svg-wow.org/graffitis/graffitis.xhtml',
                            description: 'GML playback in SVG.' }]
  ]
  owner = User.first
  if owner
    records = apps.map do |name, attrs|
      Visualization.find_or_create_by!(name: name) do |app|
        app.assign_attributes(attrs.merge(user: owner, approved_at: 1.day.ago))
      end
    end
    test_names = [nil, '', 'rl', 'ratelimit', 'x', 'curltest', 'keytest', 'TestApp']
    # update_columns on purpose: saving would re-read each row's GML from disk,
    # and only the app name changes.
    Tag.where(application: test_names).order(:id).each_with_index do |tag, i|
      tag.update_columns(application: records[i % records.size].name) # rubocop:disable Rails/SkipsModelValidations
    end
    # A few in New York and a few with views, so every front-page set shows.
    Tag.order(:id).limit(24).each_with_index do |tag, i|
      tag.update_columns(location: (i % 4).zero? ? 'New York, NY' : tag.location, # rubocop:disable Rails/SkipsModelValidations
                         views_count: [0, 3, 12, 40][i % 4])
    end
  end
end
