import SignupForm from "@/components/SignupForm";

export default function Home() {
  return (
    <>
      <nav>
        <div className="brand">GSB Closet</div>
        <div className="links">
          <a href="#how">How it works</a>
          <a href="#trust">Trust</a>
          <a href="#faq">FAQ</a>
          <a href="#signup" className="signin">Sign in</a>
        </div>
      </nav>

      <section className="hero">
        <div>
          <div className="kicker"><span></span>Private beta · GSB Class of &#39;26 + &#39;27</div>
          <h1>Your friends&#39;<br/>closets,<br/><em>borrowable.</em></h1>
          <p>A private dress-sharing network for the Stanford GSB community. Borrow what your friends already own. No middleman. No retail markup.</p>
          <div className="cta-row">
            <a href="#signup" className="cta-primary">Request invite</a>
            <a href="#how" className="cta-secondary">How it works</a>
          </div>
        </div>
        <div className="collage">
          <div className="swatch swatch-1"><div className="label">Reformation · Ivory</div></div>
          <div className="swatch swatch-2"><div className="label">Saloni · Emerald</div></div>
          <div className="swatch swatch-3"><div className="label">Markarian · Blush</div></div>
          <div className="swatch swatch-4"><div className="label">Galvan · Bordeaux</div></div>
        </div>
      </section>

      <section className="how" id="how">
        <div className="section-eyebrow">How it works</div>
        <h2 className="section-title">A million weddings.<br/><em>One closet between us.</em></h2>
        <div className="steps">
          <div className="step">
            <div className="n">01</div>
            <h3>Upload what you own</h3>
            <p>Three photos and a few details. Most members upload their first dress in under 90 seconds.</p>
          </div>
          <div className="step">
            <div className="n">02</div>
            <h3>Browse your friends&#39; closets</h3>
            <p>Filter by occasion, size, length. Everything you see comes from someone in your network.</p>
          </div>
          <div className="step">
            <div className="n">03</div>
            <h3>Borrow, wear, return</h3>
            <p>Pay your friend dry-cleaning plus a small fee — usually $30–60. Venmo. No middleman.</p>
          </div>
        </div>
      </section>

      <section className="money">
        <div className="money-inner">
          <div className="section-eyebrow">The math</div>
          <h2 className="section-title">A wedding-guest dress<br/>costs <em>$30</em>, not <em>$300</em>.</h2>
          <div className="money-grid">
            <div className="money-list">
              <p>The average GSB woman has <strong>11 formal dresses</strong> in her closet, each worn an average of <strong>1.4 times</strong>.</p>
              <p>That&#39;s a $5,000 graveyard hanging in your dorm.</p>
              <p>What if you could borrow any of them from people you already know — for the cost of dry cleaning plus enough to thank them?</p>
            </div>
            <div className="money-card">
              <div className="vs">Borrowing from a friend</div>
              <div className="row"><span>Borrow fee</span><span>$35</span></div>
              <div className="row"><span>Dry cleaning (est.)</span><span>$22</span></div>
              <div className="row total"><span>Total</span><span>$57</span></div>
              <div className="vs">vs. buying retail</div>
              <div className="row total" style={{borderTop:"none",paddingTop:0}}>
                <span style={{opacity:0.5}}>Reformation Ivory Slip</span><span>$348</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="trust" id="trust">
        <div className="section-eyebrow">Why it works</div>
        <h2 className="section-title">Private by design.<br/><em>Trusted by default.</em></h2>
        <div className="trust-grid">
          <div className="trust-card">
            <h4>Stanford-verified or invited</h4>
            <p>Every member signs up with a Stanford email or a direct invite from someone already inside. No randoms.</p>
          </div>
          <div className="trust-card">
            <h4>Friends-of-friends only</h4>
            <p>You only see closets from people in your network. Closets stay invisible to strangers.</p>
          </div>
          <div className="trust-card">
            <h4>No payments to us</h4>
            <p>You Venmo your friend directly. We don&#39;t take a cut, hold your money, or sell your data.</p>
          </div>
          <div className="trust-card">
            <h4>Built for the GSB calendar</h4>
            <p>Wedding season, Class Day, recruiting cocktails, FOAM. The events you actually have on your calendar.</p>
          </div>
        </div>
      </section>

      <section className="faq" id="faq">
        <div className="section-eyebrow" style={{marginBottom:"24px"}}>Common questions</div>
        <details open>
          <summary>Who can join?</summary>
          <p>Right now, anyone with a Stanford email (@stanford.edu or @gsb.stanford.edu), plus their direct invitees. We&#39;re starting with GSB &#39;26 and &#39;27 and expanding from there.</p>
        </details>
        <details>
          <summary>Do I have to upload to borrow?</summary>
          <p>For the beta, yes — at least one piece. The whole thing only works if everyone contributes.</p>
        </details>
        <details>
          <summary>What if a dress comes back damaged?</summary>
          <p>You agree on terms directly with the lender. We recommend a $50–100 damage deposit for high-value pieces.</p>
        </details>
        <details>
          <summary>How is this different from Pickle or Rent the Runway?</summary>
          <p>Pickle is open to strangers and hard to filter. Rent the Runway carries inventory and charges retail-adjacent prices. GSB Closet is your friends, your network, and the cost of dry cleaning.</p>
        </details>
        <details>
          <summary>How do payments work?</summary>
          <p>Through Venmo, directly between you and the lender. We don&#39;t process payments and we don&#39;t take a cut.</p>
        </details>
        <details>
          <summary>Is my closet visible to everyone?</summary>
          <p>No. Only your direct friends and friends-of-friends in the network can see it.</p>
        </details>
      </section>

      <section className="signup" id="signup">
        <h2>Join the <em>private beta.</em></h2>
        <p>Stanford GSB students and their guests. We&#39;ll be in touch within 48 hours.</p>
        <SignupForm />
        <div className="meta">No spam. Stanford emails only.</div>
      </section>

      <footer>
        <div>© 2026 GSB Closet · Made for the Class of &#39;26</div>
        <div>
          <a href="#">Privacy</a>
          <a href="#">Terms</a>
          <a href="mailto:hello@gsbcloset.com">Contact</a>
        </div>
      </footer>
    </>
  );
}
